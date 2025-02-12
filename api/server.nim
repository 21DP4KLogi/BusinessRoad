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
  let
    sentSalt = reqBody[0]
    sentSignature = reqBody[1]
    sentSecretNumber = reqBody[2].parseInt
  if verifyPowResponse(sentSalt, sentSignature, sentSecretNumber):
    resp 200, "is good"
  else:
    resp 400, "ew"

post "/register":
  let newCode: string = urandom(6).encode
  var playerQuery = newPlayer(newCode)
  psql:
    db.insert(playerQuery)
  headers["Content-Type"] = "text/plain"
  resp 200, newCode

post "/login":
  headers["Content-Type"] = "text/plain"
  let codeReq = request.body
  if codeReq.len != 8:
    resp 400, "code is malformed"
  var codeValid = false
  psql:
    codeValid = db.exists(Player, "code = $1", codeReq)
  if codeValid:
    resp 200, "auth token goes here"
  else:
    resp 400, "who the hell are you"

