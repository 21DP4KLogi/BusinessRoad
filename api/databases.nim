import ready
import norm/[postgres, types, pool, pragmas, model]
import std/[os, macros]
import "models.nim"
import "env.nim"

export ready
export postgres, types
export models


const Dbtimeout = 5
echo "Connecting to Valkey:"
for i in 1..Dbtimeout:
  echo "  Attempt: " & $i
  try:
    # Opens to test if connection possible, and if so, also closes.
    newRedisConn(VK_HOST, VK_PORT).close()
    echo "  Connected!"
    break
  except:
    sleep(1000)
    if i == Dbtimeout:
      raise newException(OSError, "Could not connect to database")
    continue

echo "Connecting to PostgreSQL:"
for i in 1..Dbtimeout:
  echo "  Attempt: " & $i
  try:
    # Opens to test if connection possible, and if so, also closes.
    getDb().close()
    echo "  Connected!"
    break
  except:
    sleep(1000)
    if i == Dbtimeout:
      raise newException(OSError, "Could not connect to database")
    continue

let valkeyPool*: RedisPool = newRedisPool(4, VK_HOST, VK_PORT)
let valkeySingle*: RedisConn = newRedisConn(VK_HOST, VK_PORT)

var psqlPool = newPool[DbConn](8)
let psqlSingle* = getDb()

template psql*(body: untyped) =
  {.gcsafe.}:
    withDb(psqlPool):
      body

template modelTableName*(model: typedesc[Model]): string =
  '"' & model.getCustomPragmaVal(tableName) & '"'
