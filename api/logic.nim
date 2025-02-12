import std/[os]
import "psql.nim"

let db = psqlSingle

proc computeGameLogic* =
  var i = 0
  while true:
    sleep(1000)
    i += 1
    stdout.write "\rDebug ticker: " & $i
    stdout.flushFile
