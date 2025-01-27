import mummy, mummy/routers
import ready
import std/[os, sysrand, base64]
import norm/[postgres, types, pool]
import "psql.nim"
import "models.nim"

# Connections
let valkey = newRedisConn("localhost", Port(5003))

proc pingHandler(request: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, "pong")

proc valkeyCounter(request: Request) = 
  let count = valkey.command("INCR", "valkeyTest")
  echo count
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, $count)

proc registerHandler(request: Request) =
  let newCode: string = urandom(6).encode
  var playerQuery = newPlayer(newCode)
  psql:
    db.insert(playerQuery)
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, newCode)
  
# Valkey setup
discard valkey.command("SET", "valkeyTest", "0")
# PostgreSQL setup
psql:
  db.createTables(newPlayer())

var router: Router
router.get("/ping", pingHandler)
router.get("/counter", valkeyCounter)
router.post("/register", registerHandler)

let server = newServer(router)
echo "Serving on http://localhost:5001"
server.serve(Port(5001))
