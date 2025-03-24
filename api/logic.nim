import std/[os]
import "databases.nim"

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
