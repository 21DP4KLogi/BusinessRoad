import std/[os]
import "psql_base.nim"
import "valkey.nim" as _

let
  db = psqlSingle
  valkey = valkeySingle

proc computeGameLogic* =
  var i = 0
  while true:
    sleep(1000)
    i += 1
    stdout.write "\rDebug ticker: " & $i
    stdout.flushFile
