import "mummy_base.nim"
import std/[locks, tables, strutils]
import "security.nim"
import "databases.nim"

var
  wsLock: Lock
  websockets: Table[WebSocket, int64]

template withLockedWs(body: untyped) =
  {.gcsafe.}:
    withLock(wsLock):
      body

get "/ws":
  let
    reqCookies = parseCookies request.headers["Cookie"]
  if not reqCookies.hasKey("a"): resp 401
  let authCookie = reqCookies["a"]
  var playerQuery = Player()
  psql:
    if not db.exists(Player, "authToken = $1", authCookie):
      resp 401
    db.select(playerQuery, "authToken = $1", authCookie)
  withLockedWs:
    websockets[request.upgradeToWebSocket()] = playerQuery.id

proc messageHandler(ws: WebSocket, event: WebSocketEvent, message: Message) =
  if message.data == "i":
    ws.send("o")
    return
  # ^ Player independent
  # v Player specific
  var playerId = 0
  var playerQuery = Player()
  withLockedWs:
    playerId = websockets[ws]
  psql:
    db.select(playerQuery, "id = $1", playerId)

  if message.data.contains '@': # Has parameter/s
    let parsedMessage = message.data.split '@'
    if parsedMessage.len != 2:
      ws.send "ERR"
      return
    let
      command = parsedMessage[0]
      parameters = parsedMessage[1].split ':'
    case command
    else:
      return

  else: # No parameters
    case message.data
    of "m?":
      ws.send $playerQuery.money
    else:
      ws.send('"' & message.data & "\", to you too")

proc websocketHandler*(
  websocket: WebSocket,
  event: WebSocketEvent,
  message: Message
) =
  case event:
  of OpenEvent:
    discard
  of MessageEvent:
    messageHandler(websocket, event, message)
  of ErrorEvent:
    discard
  of CloseEvent:
    withLockedWs:
      websockets.del(websocket)

