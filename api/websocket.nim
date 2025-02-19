import "mummy_base.nim"
import std/[locks, sets]

var
  wsLock: Lock
  websockets: HashSet[WebSocket]

template withLockedWs(body: untyped) =
  {.gcsafe.}:
    withLock(wsLock):
      body

get "/ws":
  discard request.upgradeToWebSocket()

proc websocketHandler*(
  websocket: WebSocket,
  event: WebSocketEvent,
  message: Message
) =
  case event:
  of OpenEvent:
    {.gcsafe.}:
      withLock(wsLock):
        websockets.incl websocket
  of MessageEvent:
    websocket.send('"' & message.data & "\", to you too")
  of ErrorEvent:
    discard
  of CloseEvent:
    withLockedWs:
      websockets.excl websocket
