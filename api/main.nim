import mummy, mummy/routers
import ready
import std/[sysrand, base64]
import "psql.nim"
import "motd.nim"

template get(endpoint: string, body: untyped) =
  router.get(endpoint, RequestHandler(proc (request {.inject.}: Request) {.gcsafe.} =
    var headers {.inject.}: HttpHeaders
    body
  ))

template post(endpoint: string, body: untyped) =
  router.post(endpoint, RequestHandler(proc (request {.inject.}: Request) {.gcsafe.} =
    var headers {.inject.}: HttpHeaders
    body
  ))

# Valkey setup
let valkey = newRedisPool(4, "localhost", Port(5003))
discard valkey.command("SET", "valkeyTest", "0")
valkey.randomizeMotd()
# PostgreSQL setup
psql:
  db.createTables(newPlayer())
# Mummy router definition
var router: Router

get "/ping":
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, "pong")

get "/counter":
  let count = valkey.command("INCR", "valkeyTest")
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, $count)

get "/motd":
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, valkey.getMotd)

post "/register":
  let newCode: string = urandom(6).encode
  var playerQuery = newPlayer(newCode)
  psql:
    db.insert(playerQuery)
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, newCode)

post "/login":
  headers["Content-Type"] = "text/plain"
  let codeReq = request.body
  if codeReq.len != 8:
    request.respond(400, headers, "code is malformed")
  var codeValid = false
  psql:
    codeValid = db.exists(Player, "code = $1", codeReq)
  if codeValid:
    request.respond(200, headers, "auth token goes here")
  else:
    request.respond(400, headers, "who the hell are you")

let server = newServer(router)
echo "Serving on http://localhost:5001"
server.serve(Port(5001))
