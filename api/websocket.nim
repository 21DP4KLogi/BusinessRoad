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
      ws.send "ERR=Invalid"
      return
    let
      command = parsedMessage[0]
      parameters = parsedMessage[1].split ':'
    case command

    of "foundBusiness":
      if
        invalidParameters(parameters, 1) or
        playerQuery.money < 5000 or
        invalidInt16(parameters[0])
        :
        ws.send("ERR=Invalid")
        return
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
        "employees": {},
        "interviewees": {},
        "projects": {},
      })
      ws.send("m=" & $playerQuery.money)

    of "findEmployees":
      if
        "" in parameters or
        parameters[0].containsAnythingBut(Digits) or
        parameters[0].len > SafeInt64Len
        :
        ws.send("ERR=Invalid")
        return
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
        invalidParameters(parameters, 3) or
        invalidInt64(parameters[0]) or
        invalidInt64(parameters[1]) or
        invalidInt32(parameters[2])
        :
        ws.send("ERR=Invalid")
        return
      let
        sentEmployeeId = parameters[0].parseInt
        sentBusinessId = parameters[1].parseInt
        sentProposedSalary = int32(parameters[2].parseInt)
      var employeeQuery = Employee()
      psql:
        if not db.exists(
          Employee,
          "id = $1 AND interview IN (SELECT id FROM " & modelTableName(Business) & " WHERE owner = $2)",
          sentEmployeeId, playerId
        ):
          ws.send("ERR=Not authorised")
          return
        db.select(employeeQuery, "id = $1", sentEmployeeId)
      let hagglingDiff = sentProposedSalary / employeeQuery.salary
      if hagglingDiff < 1.0: # Salary decrease
        let
          chanceToAccept = pow(hagglingDiff, 3)
        if rand(0.01..1.0) <= chanceToAccept: # Accepts haggle
          employeeQuery.salary = sentProposedSalary
          employeeQuery.loyalty = int16(float(employeeQuery.loyalty) * hagglingDiff/2)
          psql:
            db.update(employeeQuery)
          ws.send("updateinterviewee=" & colonSerialize(sentBusinessId, sentEmployeeId, sentProposedSalary))
          return
        else: # Refuses haggle
          employeeQuery.loyalty = int16(float(employeeQuery.loyalty) * hagglingDiff)
          if employeeQuery.loyalty <= 500:
            employeeQuery.interview = none int64
            psql:
              db.update(employeeQuery)
            ws.send("loseinterviewee=" & colonSerialize(sentBusinessId, sentEmployeeId))
            return
          elif employeeQuery.loyalty < 5000 and rand(0.0001..1.0) < (5000 - employeeQuery.loyalty) / 5000:
            employeeQuery.interview = none int64
            psql:
              db.update(employeeQuery)
            ws.send("loseinterviewee=" & colonSerialize(sentBusinessId, sentEmployeeId))
            return
          else:
            ws.send("updateinterviewee=" & colonSerialize(sentBusinessId, sentEmployeeId, employeeQuery.salary))
            return
      elif hagglingDiff > 1.0: # Salary increase
          employeeQuery.salary = sentProposedSalary
          employeeQuery.loyalty = int16(float(employeeQuery.loyalty) * ((hagglingDiff - 1)/2 + 1))
          psql:
            db.update(employeeQuery)
          ws.send("updateinterviewee=" & colonSerialize(sentBusinessId, sentEmployeeId, sentProposedSalary))
          return
      else: # Salary equal for some reason
        ws.send("updateinterviewee=" & colonSerialize(sentBusinessId, sentEmployeeId, sentProposedSalary))
        discard

    of "hireEmployee":
    # IMPORTANT TODO: Validate user's authorisation
      if
        invalidParameters(parameters, 2) or
        invalidInt64(parameters[0]) or
        invalidInt64(parameters[1])
        :
        ws.send("ERR=Invalid")
        return
      let sentBusinessId = int64(parameters[0].parseInt)
      let sentEmployeeId = int64(parameters[1].parseInt)
      psql:
        if not db.exists(Employee, "id = $1 AND interview = $2", sentEmployeeId, sentBusinessId):
          ws.send "ERR=No applicable interviewee"
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
        invalidParameters(parameters, 2) or
        invalidInt64(parameters[0]) or
        invalidInt64(parameters[1])
        :
        ws.send("ERR=Invalid")
        return
      let sentBusinessId = int64(parameters[0].parseInt)
      let sentEmployeeId = int64(parameters[1].parseInt)
      psql:
        if not db.exists(Employee, "id = $1 AND workplace = $2", sentEmployeeId, sentBusinessId):
          ws.send "ERR=No applicable interviewee"
          return
        var employeeQuery = Employee()
        db.select(employeeQuery, "id = $1 AND workplace = $2", sentEmployeeId, sentBusinessId)
        employeeQuery.workplace = none int64
        employeeQuery.interview = none int64
        db.update(employeeQuery)
      ws.send("loseemployee=" & colonSerialize(sentBusinessId, sentEmployeeId))
      return

    of "createProject":
      if
        invalidParameters(parameters, 2) or
        invalidInt64(parameters[0]) or
        invalidInt16(parameters[1])
        :
        ws.send("ERR=Invalid")
        return
      let sentProjectType = parameters[1].parseInt
      if sentProjectType notin BusinessProject:
        ws.send("ERR=Invalid business project")
        return
      let sentBusinessId = parameters[0].parseInt
      var businessQuery = Business()
      var projectQuery = Project()
      psql:
        if not db.exists(Business, "id = $1 AND owner = $2", sentBusinessId, playerId):
          ws.send("ERR=Not authorised")
          return
        db.select(businessQuery, "id = $1", sentBusinessId)
        if BusinessProject(sentProjectType) notin availableProjects[businessQuery.field]:
          ws.send("ERR=Project type not available for given business")
          return
        let
          employeeCount = db.count(Employee, "*", dist=false, "workplace = $1", sentBusinessId)
          activeProjectCount = db.count(Project, "*", dist=false, "business = $1 AND active = TRUE", sentBusinessId)
        projectQuery = Project(
          business: sentBusinessId,
          project: BusinessProject(sentProjectType),
          active: if employeeCount >= triangleNumber(activeProjectCount + 1): true else: false,
        )
        db.insert(projectQuery)
      ws.send("newproject=" & $ %*{
        "id": projectQuery.id,
        "business": projectQuery.business,
        "project": projectQuery.project,
        "quality": projectQuery.quality,
        "active": projectQuery.active,
      })

    of "dproj":
      if
        invalidParameters(parameters, 2) or
        invalidInt64(parameters[0]) or
        invalidInt64(parameters[1])
        :
        ws.send("ERR=Invalid")
        return
      let sentBusinessId = parameters[0].parseInt
      let sentProjectId = parameters[1].parseInt
      psql:
        if not db.exists(Business, "id = $1 AND owner = $2", sentBusinessId, playerId):
          ws.send("ERR=Not authorised")
          return
        if not db.exists(Project, "id = $1 AND business = $2", sentProjectId, sentBusinessId):
          ws.send("ERR=Not authorised")
          return
        var projectQuery = Project()
        db.select(projectQuery, "id = $1", sentProjectId)
        if projectQuery.contract != none int64:
          ws.send("ERR=Project in contract")
          return
        db.delete(projectQuery)
      ws.send("dproj=" & colonSerialize(sentBusinessId, sentProjectId))


      discard

    of "wprojactive":
      if
        invalidParameters(parameters, 3) or
        invalidInt64(parameters[0]) or
        invalidInt64(parameters[1]) or
        parameters[2] notin ["T", "F"]
        :
        ws.send("ERR=Invalid")
        return
      let
        sentBusinessId = parameters[0].parseInt
        sentProjectId = parameters[1].parseInt
        sentProjectStatus: bool = parameters[2] == "T"
      psql:
        if
          not playerId.ownsBusiness(db, sentBusinessId) or
          not sentBusinessId.ownsProject(db, sentProjectId)
          :
          ws.send("ERR=Not authorised")
          return
        let
          employeeCount = db.count(Employee, "*", dist=false, "workplace = $1", sentBusinessId)
          activeProjectCount = db.count(Project, "*", dist=false, "business = $1 AND active = TRUE", sentBusinessId)
        # Active project limit is TriangleNumber(employeeCount)
        if
          sentProjectStatus == true and
          employeeCount < triangleNumber(activeProjectCount + 1)
          :
          ws.send("ERR=Not enough employees")
          return
        var projectQuery = Project()
        db.select(projectQuery, "id = $1", sentProjectId)
        projectQuery.active = sentProjectStatus
        db.update(projectQuery)
      ws.send("wprojactive=" & colonSerialize(
        sentBusinessId,
        sentProjectId,
        if sentProjectStatus: "T" else: "F"
        )
      )
      return

    else:
      ws.send "ERR=Unknown command (with parameter)"
      return

  else: # No parameters
    case message.data
    of "m?":
      ws.send $playerQuery.money
    else:
      ws.send "ERR=Unknown command (without parameter)"
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

