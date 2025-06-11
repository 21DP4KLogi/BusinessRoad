import "databases.nim"
import "motd.nim"
import "logic.nim"
import "security.nim"

import "mummy_base.nim"
import "routes.nim" # Has effect, despite not being considered used
import "websocket.nim"
import "env.nim"

# Valkey setup
let valkey = valkeySingle
discard valkey.command("SET", "currentMotd", getRandomMotd())
discard valkey.command("SET", "powSignatureKey", secureRandomBase64(18))

# PostgreSQL setup
let db = psqlSingle
db.createTables(Player())
db.createTables(Business())
db.createTables(Employee())
db.createTables(Contract())
db.createTables(Project())

# Game logic computer setup
var thread: Thread[void]
createThread(thread, computeGameLogic)

# API server setup
let apiServer = newServer(router, websocketHandler)

# API server launch
echo "Serving on http://localhost:5001"
echo "- - - - - - - - - -"
apiServer.serve(API_PORT, API_HOST)
