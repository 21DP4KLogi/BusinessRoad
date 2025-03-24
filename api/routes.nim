import "mummy_base.nim"
import std/[strutils, tables, options, json]
import "security.nim"
import "databases.nim"
import "lang_base.nim"

let valkey = valkeyPool

proc getUserGameData(player: Player): JsonNode =
  return %* {
    "firstname": player.firstname,
    "lastname": player.lastname,
    "money": player.money,
    "gender": player.gender,
  }

get "/init":
  let
    userCookie = request.headers.getAuthCookie()
    userAuthenticated = authCookieValid(userCookie)

  var gameData: JsonNode = newJNull()
  if userAuthenticated:
    psql:
      var playerQuery = Player()
      db.select(playerQuery, "authToken = $1", userCookie)
      gameData = getUserGameData(playerQuery)
  
  let motdData = valkey.command("GET", "currentMotd").to(string)
  
  headers["Content-Type"] = "application/json"
  resp 200, $ %* {
    "lengths": {
      "F": {
        "firstname": FemaleFirstNameCount,
        "lastname": FemaleLastNameCount,
      },
      "M": {
        "firstname": MaleFirstNameCount,
        "lastname": MaleLastNameCount,
      }
    },
    "gameData": gameData,
    "motd": motdData,
    "lang": langs["en"],
  }

get "/setlang/@lang":
  let sentLang = request.pathParams["lang"]
  headers["Content-Type"] = "application/json"
  if not langs.hasKey(sentLang): resp 404
  #TODO: Make selection persistant, likely via cookie
  resp 200, langs[sentLang]

get "/challenge":
  headers["Content-Type"] = "text/plain"
  valkey.withConnection vk:
    resp 200, generatePowChallenge(vk)

post "/register":
  let body = request.body.split(":")
  if
    body.len != 6 or
    "" in body or
    body[0].containsAnythingBut(UppercaseHexDigits) or
    body[0].len != SaltHexLength or
    body[1].containsAnythingBut(UppercaseHexDigits) or
    body[1].len != HashSignatureHexLenght or
    body[2].containsAnythingBut(Digits) or
    body[3].containsAnythingBut({'M', 'F'}) or
    body[4].containsAnythingBut(Digits) or
    body[5].containsAnythingBut(Digits)
    : resp 400
  let
    sentSalt = body[0]
    sentSignature = body[1]
    sentSecretNumber = body[2].parseInt
    sentGender = body[3]
    # BUG: no check for numbers being within valid range and that can cause a 500 error
    sentFName = int16(body[4].parseInt)
    sentLName = int16(body[5].parseInt)

  if sentGender == "M":
    if sentFName >= MaleFirstNameCount or sentLName >= MaleLastNameCount:
      resp 400
  else:
    if sentFName >= FemaleFirstNameCount or sentLName >= FemaleLastNameCount:
      resp 400

  valkey.withConnection vk:
    if vk.submitPowResponse(sentSalt, sentSignature, sentSecretNumber):
      let newCode: string = secureRandomBase64(6)
      var playerQuery = Player(
        code: newPaddedStringOfCap[8](newCode),
        gender: newPaddedStringOfCap[1](sentGender),
        firstname: sentFName,
        lastname: sentLName
      )
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
  valkey.withConnection vk:
    if not vk.submitPowResponse(sentSalt, sentSignature, sentSecretNumber): resp 401
  psql:
    let codeValid = db.exists(Player, "code = $1", sentCode)
    if not codeValid: resp 404
    let authCookie = secureRandomBase64(9)
    var playerQuery = Player()
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
    headers["Content-Type"] = "application/json"
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
  valkey.withConnection vk:
    if vk.submitPowResponse(sentSalt, sentSignature, sentSecretNumber):
      var codeValid = false
      psql:
        codeValid = db.exists(Player, "code = $1", sentCode)
        if codeValid:
          var playerQuery = Player()
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
