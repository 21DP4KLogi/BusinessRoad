import norm/[postgres, types, pool]
import std/[os]
import "models.nim"

export postgres, types
export models

putEnv("DB_HOST", "localhost:5002")
putEnv("DB_USER", "businessman")
putEnv("DB_PASS", "hunter2")
putEnv("DB_NAME", "BusinessRoadDev")
var psqlPool = newPool[DbConn](8)

template psql*(body: untyped) =
  {.gcsafe.}:
    withDb(psqlPool):
      body
