import std/[os]

proc computeGameLogic* =
  var i = 0
  while true:
    sleep(1000)
    i += 1
    echo i
