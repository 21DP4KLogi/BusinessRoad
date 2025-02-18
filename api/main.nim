import "server.nim"
import "valkey.nim" as valkeyFile # 'as' added to prevent name conflict with 'valkey' variable
import "psql.nim"
import "motd.nim"
import "logic.nim"
import "pow.nim"

# Valkey setup
discard valkey.command("SET", "valkeyTest", "0")
valkey.randomizeMotd()
generateHmacKeyForPow()

# PostgreSQL setup
psql:
  db.createTables(newPlayer())

# Game logic computer setup
var thread: Thread[void]
createThread(thread, computeGameLogic)

# API server setup
let apiServer = newServer(router, websocketHandler)

# API server launch
echo "Serving on http://localhost:5001"
apiServer.serve(Port(5001))
