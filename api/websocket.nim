import "mummy_base.nim"
import std/[locks, tables, strutils, json, options, random, macros, math]
import "security.nim"
import "databases.nim"
import norm/pragmas

var
  wsLock: Lock
  websocketsByWs: Table[WebSocket, int64]
  websocketsById*: Table[int64, WebSocket]

template withLockedWs*(body: untyped) =
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
  let ws = request.upgradeToWebSocket()
  withLockedWs:
    websocketsByWs[ws] = playerQuery.id
    websocketsById[playerQuery.id] = ws

proc messageHandler(ws: WebSocket, event: WebSocketEvent, message: Message) =
  if message.data == "i":
    ws.send("o")
    return
  # ^ Player independent
  # v Player specific
  var playerId = 0
  var playerQuery = Player()
  withLockedWs:
    playerId = websocketsByWs[ws]
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

    of "foundBusiness":
      if
        playerQuery.money < 5000 or
        parameters.len > 1 or
        parameters[0].containsAnythingBut(Digits) or
        parameters[0].len > SafeInt16Len
        : return
      let sentField = parameters[0].parseInt
      if sentField notin BusinessField: return

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
      if
        parameters[0].containsAnythingBut(Digits) or
        parameters[0].len > SafeInt64Len
      : return
      let sentBusinessId = int64(parameters[0].parseInt)
      psql:
        if not db.exists(Business, "id = $1 AND owner = $2", sentBusinessId, playerId):
          return
        db.exec(sql"""
          UPDATE "Employees" SET interview = NULL WHERE interview = $1;
        """, sentBusinessId)
        let unemployedWorkerCount = db.count(Employee, cond = "workplace IS NULL")
        if unemployedWorkerCount == 0:
          ws.send("interviewees=" & $ %* {"business": sentBusinessId, "interviewees": []})
          return
        var employeeQuery = @[Employee()]
        var employeeList: seq[frontendEmployee] = @[]
        db.select(employeeQuery, "workplace IS NULL ORDER BY RANDOM() LIMIT 3")
        for emp in employeeQuery:
          var employee = emp
          employee.interview = some sentBusinessId
          employee.salary = int32(float64(employee.experience) * rand(0.8..1.2))
          employee.loyalty = int16(rand(4000..6000))
          db.update(employee)
          employeeList.add frontendEmployee(
            # There is probably some syntactic sugar for this
            id: emp.id,
            salary: emp.salary,
            proficiency: emp.proficiency,
            gender: emp.gender,
            firstname: emp.firstname,
            lastname: emp.lastname
          )
        ws.send("interviewees=" & $ %* {"business": sentBusinessId, "interviewees": employeeList})

    of "haggleWithInterviewee":
      if
        parameters.len != 3 or
        parameters[0].containsAnythingBut(Digits) or
        parameters[0].len > SafeInt64Len or
        parameters[1].containsAnythingBut(Digits) or
        parameters[1].len > SafeInt64Len or
        parameters[2].containsAnythingBut(Digits) or
        parameters[2].len > SafeInt32Len
        : return
      let
        sentEmployeeId = parameters[0].parseInt
        sentBusinessId = parameters[1].parseInt
        sentProposedSalary = int32(parameters[2].parseInt)
      var employeeQuery = Employee()
      psql:
        if not db.exists(
          Employee,
          "id = $1 AND interview IN (SELECT * FROM " & modelTableName(Business) & " WHERE owner = $2)",
          sentEmployeeId, playerId
        ):
          return
        db.select(employeeQuery, "id = $1", sentEmployeeId)
      let hagglingDiff = sentProposedSalary / employeeQuery.salary
      if hagglingDiff < 1.0: # Salary decrease
        let
          chanceToAccept = pow(1 - hagglingDiff, 3)
        if rand(0.01..1.0) <= chanceToAccept: # Accepts haggle
          employeeQuery.salary = sentProposedSalary
          employeeQuery.loyalty = int16(float(employeeQuery.loyalty) * hagglingDiff/2)
          ws.send("updateinterviewee=" & colonSerialize(sentBusinessId, sentEmployeeId, sentProposedSalary))
          return
        else: # Refuses haggle
          employeeQuery.loyalty = int16(float(employeeQuery.loyalty) * hagglingDiff)
          if employeeQuery.loyalty <= 500:
            employeeQuery.interview = none int64
            ws.send("loseinterviewee=" & colonSerialize(sentBusinessId, sentEmployeeId))
            return
          elif employeeQuery.loyalty < 5000 and rand(0.0001..1.0) < (5000 - employeeQuery.loyalty) / 5000:
            employeeQuery.interview = none int64
            ws.send("loseinterviewee=" & colonSerialize(sentBusinessId, sentEmployeeId))
            return
      elif hagglingDiff > 1.0: # Salary increase
          employeeQuery.salary = sentProposedSalary
          employeeQuery.loyalty = int16(float(employeeQuery.loyalty) * ((hagglingDiff - 1)/2 + 1))
          ws.send("updateinterviewee=" & colonSerialize(sentBusinessId, sentEmployeeId, sentProposedSalary))
          return
      else: # Salary equal for some reason
        discard

    of "hireEmployee":
    # IMPORTANT TODO: Validate user's authorisation
      if
        parameters.len != 2 or
        parameters[0].containsAnythingBut(Digits) or
        parameters[0].len > SafeInt64Len or
        parameters[1].containsAnythingBut(Digits) or
        parameters[1].len > SafeInt64Len
        : return
      let sentBusinessId = int64(parameters[0].parseInt)
      let sentEmployeeId = int64(parameters[1].parseInt)
      psql:
        if not db.exists(Employee, "id = $1 AND interview = $2", sentEmployeeId, sentBusinessId):
          ws.send "ERR"
          return
        var employeeQuery = Employee()
        db.select(employeeQuery, "id = $1 AND interview = $2", sentEmployeeId, sentBusinessId)
        employeeQuery.workplace = some sentBusinessId
        employeeQuery.interview = none int64
        db.update(employeeQuery)
      ws.send("newemployee=" & colonSerialize(sentBusinessId, sentEmployeeId))
      return

    of "fireEmployee":
    # IMPORTANT TODO: Validate user's authorisation
      if
        parameters.len != 2 or
        parameters[0].containsAnythingBut(Digits) or
        parameters[0].len > SafeInt64Len or
        parameters[1].containsAnythingBut(Digits) or
        parameters[1].len > SafeInt64Len
        : return
      let sentBusinessId = int64(parameters[0].parseInt)
      let sentEmployeeId = int64(parameters[1].parseInt)
      psql:
        if not db.exists(Employee, "id = $1 AND workplace = $2", sentEmployeeId, sentBusinessId):
          ws.send "ERR"
          return
        var employeeQuery = Employee()
        db.select(employeeQuery, "id = $1 AND workplace = $2", sentEmployeeId, sentBusinessId)
        employeeQuery.workplace = none int64
        employeeQuery.interview = none int64
        db.update(employeeQuery)
      ws.send("loseemployee=" & colonSerialize(sentBusinessId, sentEmployeeId))
      return
        

    else:
      ws.send "ERR"
      return

  else: # No parameters
    case message.data
    of "m?":
      ws.send $playerQuery.money
    else:
      ws.send "ERR"
      # ws.send('"' & message.data & "\", to you too")

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
      websocketsById.del(websocketsByWs[websocket])
      websocketsByWs.del(websocket)

