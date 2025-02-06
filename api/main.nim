import mummy, mummy/routers
import ready
import std/[sysrand, base64]
import "psql.nim"
import "motd.nim"

# Connections
let valkey = newRedisPool(4, "localhost", Port(5003))

proc pingHandler(request: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, "pong")

proc valkeyCounter(request: Request) = 
  let count = valkey.command("INCR", "valkeyTest")
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, $count)

proc motdHandler(request: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, valkey.getMotd)

proc registerHandler(request: Request) =
  let newCode: string = urandom(6).encode
  var playerQuery = newPlayer(newCode)
  psql:
    db.insert(playerQuery)
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, newCode)

proc loginHandler(request: Request) =
  var headers: HttpHeaders
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
  
# Valkey setup
discard valkey.command("SET", "valkeyTest", "0")
valkey.randomizeMotd()
# PostgreSQL setup
psql:
  db.createTables(newPlayer())

var router: Router
router.get("/ping", pingHandler)
router.get("/counter", valkeyCounter)
router.get("/motd", motdHandler)
router.post("/register", registerHandler)
router.post("/login", loginHandler)

let server = newServer(router)
echo "Serving on http://localhost:5001"
server.serve(Port(5001))
