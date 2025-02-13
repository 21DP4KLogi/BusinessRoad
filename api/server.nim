import mummy, mummy/routers
import std/[sysrand, base64, strutils, parseutils]
import "pow.nim"
import "valkey.nim" as valkeyFile
import "psql.nim"
import "motd.nim"

export mummy, routers

# Mummy router definition
var router*: Router

# Templates for Jester syntax
template get*(endpoint: string, body: untyped) =
  router.get(endpoint, RequestHandler(proc (request {.inject.}: Request) {.gcsafe.} =
    var headers {.inject.}: HttpHeaders
    body
  ))

template post*(endpoint: string, body: untyped) =
  router.post(endpoint, RequestHandler(proc (request {.inject.}: Request) {.gcsafe.} =
    var headers {.inject.}: HttpHeaders
    body
  ))

template resp*(code: int, body: sink string) = # I don't really know what the 'sink' does, but that is what Mummy uses.
  request.respond(code, headers, body)
  return

template resp*(code: int) =
  request.respond(code)
  return

# Apparently using the colon syntax 'usually' requires it to be the untyped type, so couldn't quite get it to work.
# template verifyAllConditions(conditions: untyped): void =
#   if (false in conditions):
#     resp 400

# Routes
get "/init":
  headers["Content-Type"] = "text/plain"
  let
    counterData = valkey.command("GET", "valkeyTest").to(string)
    motdData = valkey.getMotd()
    content = $counterData & ":" & motdData
  resp 200, content

get "/ping":
  headers["Content-Type"] = "text/plain"
  resp 200, "pong"

get "/counter":
  let count = valkey.command("INCR", "valkeyTest")
  headers["Content-Type"] = "text/plain"
  resp 200, $count

# get "/motd":
#   headers["Content-Type"] = "text/plain"
#   resp 200, valkey.getMotd

get "/challenge":
  headers["Content-Type"] = "text/plain"
  resp 200, generatePowChallenge()

post "/debugverifychallenge":
  let reqBody = request.body.split(":")
  if reqBody.len != 3:
    resp 400
  if reqBody[2].contains(AllChars - Digits):
    resp 400
  let
    sentSalt = reqBody[0]
    sentSignature = reqBody[1]
    sentSecretNumber = reqBody[2].parseInt
  if submitPowResponse(sentSalt, sentSignature, sentSecretNumber):
    resp 200, "is good"
  else:
    resp 400, "ew"

post "/register":
  let body = request.body.split(":")
  if
    body.len != 3 or
    "" in body or
    body[0].contains(AllChars - UppercaseHexDigits) or
    body[0].len != SaltHexLength or
    body[1].contains(AllChars - UppercaseHexDigits) or
    body[1].len != HashSignatureHexLenght or
    body[2].contains(AllChars - Digits)
    : resp 400
  let
    sentSalt = body[0]
    sentSignature = body[1]
    sentSecretNumber = body[2].parseInt
  if submitPowResponse(sentSalt, sentSignature, sentSecretNumber):
    let newCode: string = base64.encode urandom(6) # specifying base64 because 'encode' is quite vague
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
    body[0].contains(AllChars - Base64digits) or
    body[1].contains(AllChars - UppercaseHexDigits) or
    body[1].len != SaltHexLength or
    body[2].contains(AllChars - UppercaseHexDigits) or
    body[2].len != HashSignatureHexLenght or
    body[3].contains(AllChars - Digits)
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
      headers["Content-Type"] = "text/plain"
      resp 200, "auth token goes here"
  else:
    resp 401

