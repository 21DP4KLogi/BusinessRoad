import ready
import norm/[postgres, types, pool]
import std/[os]
import "models.nim"

export ready
export postgres, types
export models

putEnv("DB_HOST", "localhost:5002")
putEnv("DB_USER", "businessman")
putEnv("DB_PASS", "hunter2")
putEnv("DB_NAME", "BusinessRoadDev")

const Dbtimeout = 5
echo "Connecting to Valkey:"
for i in 1..Dbtimeout:
  echo "  Attempt: " & $i
  try:
    # Opens to test if connection possible, and if so, also closes.
    newRedisConn("localhost", Port(5003)).close()
    echo "  Connected!"
    break
  except:
    sleep(1000)
    if i == Dbtimeout:
      raise newException(OSError, "Could not connect to database")
    continue

let valkeyPool*: RedisPool = newRedisPool(4, "localhost", Port(5003))
let valkeySingle*: RedisConn = newRedisConn("localhost", Port(5003))

var psqlPool = newPool[DbConn](8)
let psqlSingle* = getDb()

template psql*(body: untyped) =
  {.gcsafe.}:
    withDb(psqlPool):
      body
