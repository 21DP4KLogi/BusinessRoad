import "mummy_base.nim"
import std/[strutils, tables, options, json]
import "security.nim"
import "valkey.nim" as _
import "psql_base.nim"
import "../lang"/[en as enLang]

let valkey = valkeyPool

proc getUserGameData(player: Player): JsonNode =
  return %* {
    "firstname": 1,
    "lastname": 0,
    "money": player.money,
  }

get "/init":
  let
    userCookie = request.headers.getAuthCookie()
    userAuthenticated = authCookieValid(userCookie)

  var gameData: JsonNode = newJNull()
  if userAuthenticated:
    psql:
      var playerQuery = newPlayer()
      db.select(playerQuery, "authToken = $1", userCookie)
      gameData = getUserGameData(playerQuery)
  
  let motdData = valkey.command("GET", "currentMotd").to(string)
  
  headers["Content-Type"] = "text/plain"
  resp 200, $ %* {
    "gameData": gameData,
    "motd": motdData,
    "lang": enLang.en,
  }

get "/challenge":
  headers["Content-Type"] = "text/plain"
  resp 200, generatePowChallenge()

post "/register":
  let body = request.body.split(":")
  if
    body.len != 3 or
    "" in body or
    body[0].containsAnythingBut(UppercaseHexDigits) or
    body[0].len != SaltHexLength or
    body[1].containsAnythingBut(UppercaseHexDigits) or
    body[1].len != HashSignatureHexLenght or
    body[2].containsAnythingBut(Digits)
    : resp 400
  let
    sentSalt = body[0]
    sentSignature = body[1]
    sentSecretNumber = body[2].parseInt
  if submitPowResponse(sentSalt, sentSignature, sentSecretNumber):
    let newCode: string = secureRandomBase64(6)
    var playerQuery = newPlayer(newCode)
    psql:
      db.insert(playerQuery)
    headers["Content-Type"] = "text/plain"
    resp 200, newCode
  else:
    resp 401

post "/login":
  let body = request.body.split(":")
  if
    body.len != 4 or
    "" in body or
    body[0].len != 8 or
    body[0].containsAnythingBut(Base64digits) or
    body[1].containsAnythingBut(UppercaseHexDigits) or
    body[1].len != SaltHexLength or
    body[2].containsAnythingBut(UppercaseHexDigits) or
    body[2].len != HashSignatureHexLenght or
    body[3].containsAnythingBut(Digits)
    : resp 400
  let
    sentCode = body[0]
    sentSalt = body[1]
    sentSignature = body[2]
    sentSecretNumber = body[3].parseInt
  if not submitPowResponse(sentSalt, sentSignature, sentSecretNumber): resp 401
  psql:
    let codeValid = db.exists(Player, "code = $1", sentCode)
    if not codeValid: resp 404
    let authCookie = secureRandomBase64(9)
    var playerQuery = newPlayer()
    db.select(playerQuery, "code = $1", sentCode)
    playerQuery.authToken = some newPaddedStringOfCap[12](authCookie)
    db.update(playerQuery)
    headers["Set-Cookie"] = makeCookie(
      "a", authCookie,
      expires=daysForward(7),
      path="/",
      secure=true,
      httpOnly=true,
      sameSite=Strict
    )
    headers["Content-Type"] = "text/plain"
    resp 200, $getUserGameData(playerQuery)

post "/delete":
  let body = request.body.split(":")
  if
    body.len != 4 or
    "" in body or
    body[0].len != 8 or
    body[0].containsAnythingBut(Base64digits) or
    body[1].containsAnythingBut(UppercaseHexDigits) or
    body[1].len != SaltHexLength or
    body[2].containsAnythingBut(UppercaseHexDigits) or
    body[2].len != HashSignatureHexLenght or
    body[3].containsAnythingBut(Digits)
    : resp 400
  let
    sentCode = body[0]
    sentSalt = body[1]
    sentSignature = body[2]
    sentSecretNumber = body[3].parseInt
  if submitPowResponse(sentSalt, sentSignature, sentSecretNumber):
    var codeValid = false
    psql:
      codeValid = db.exists(Player, "code = $1", sentCode)
      if codeValid:
        var playerQuery = newPlayer()
        db.select(playerQuery, "code = $1", sentCode)
        # Will be more complicated when more features get added
        db.delete(playerQuery)
        resp 204
      else:
        resp 404
  else:
    resp 401

post "/logout":
  # I'm not sure if I have to check whether the key "Cookie" exists
  let reqCookies = parseCookies request.headers["Cookie"]
  if not reqCookies.hasKey("a"): resp 401
  let authCookie = reqCookies["a"]
  psql:
    # This check might be a bit useless, will keep it for now incase of debugging
    if not db.exists(Player, "authToken = $1", authCookie): resp 404
    db.exec(sql "UPDATE \"Player\" SET authToken = NULL WHERE authToken = $1", authCookie)
  headers["Set-Cookie"] = makeCookie(
    "a", "",
    expires=daysForward(-1),
    path="/",
    secure=true,
    httpOnly=true,
    sameSite=Strict
  )
  resp 200
