import "mummy_base.nim"
import std/[locks, tables, strutils, random, json, options]
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
      # ws.send "ERR"
      return
    let
      command = parsedMessage[0]
      parameters = parsedMessage[1].split ':'
    case command

    of "foundBusiness":
      if
        playerQuery.money < 5000 or
        parameters.len > 1 or
        parameters[0].containsAnythingBut(Digits)
        : return
      let sentField = int16(parameters[0].parseInt)
      if sentField > int16(BusinessField.high): return # Not a fan of this

      playerQuery.money -= 5000
      var businessQuery = Business(
        owner: playerId,
        field: BusinessField(sentField)
      )
      psql:
        db.update(playerQuery)
        db.insert(businessQuery)
      ws.send("newbusiness=" & $ %*{
        "field": businessQuery.field,
        "id": businessQuery.id,
        "employees": [],
        "interviewees": [],
      })
      ws.send("m=" & $playerQuery.money)

    of "findEmployees":
      if parameters[0].containsAnythingBut(Digits): return
      let sentBusinessId = int64(parameters[0].parseInt())
      psql:
        if not db.exists(Business, "id = $1 AND owner = $2", sentBusinessId, playerId):
          return
        let unemployedWorkerCount = db.count(Employee, "workplace IS NULL")
        if unemployedWorkerCount == 0:
          ws.send("o") # TODO: make this informative
          return
        var range = {1..unemployedWorkerCount}
        var chosenEmployeeIds: seq[int] = @[]
        for _ in 1..3:
          # TODO: check if less than 3 workers available
          let chosenNumber = sample(range)
          chosenEmployeeIds.add chosenNumber
          range.excl chosenNumber
        var employeeQuery = Employee()
        var employeeList: seq[frontendEmployee] = @[]
        for i in chosenEmployeeIds:
          db.select(employeeQuery, "id = $1", i)
          employeeQuery.interview = some sentBusinessId
          db.update(employeeQuery)
          employeeList.add frontendEmployee(
            # There is probably some syntactic sugar for this
            id: employeeQuery.id,
            salary: employeeQuery.salary,
            proficiency: employeeQuery.proficiency,
            gender: employeeQuery.gender,
            firstname: employeeQuery.firstname,
            lastname: employeeQuery.lastname
          )
        ws.send("interviewees=" & $ %* {"business": sentBusinessId, "interviewees": employeeList})


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

