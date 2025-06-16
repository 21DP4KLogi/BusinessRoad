import std/[os, times, random, terminal, tables, options]
import "databases.nim"
import "lang_base.nim"
import "motd.nim"
import "mummy_base"
import "websocket.nim"
import "security.nim"

const
  TickRateInMs = 1000
  EmployeeToPlayerRatio = 10

const
  Second = 1
  Minute = 60 * Second
  Hour = 60 * Minute
  Day = 24 * Hour

type ModelCounts = ref object
  players, businesses, employees: int64

type TickInterval = object
  interval: float
  lastTick: float
  # offset: float

func newTickInterval(interval, time, offset: float): TickInterval =
  TickInterval(
    interval: interval,
    lastTick: time + offset
  )

func elapsed(ticker: TickInterval, currentTime: float): bool =
  ticker.lastTick + ticker.interval < currentTime

func tick(ticker: var TickInterval, currentTime: float): void =
  ticker.lastTick = currentTime

var
  currentTime = epochTime()
  lastTime = currentTime
  # secondTicker = newTickInterval(1, currentTime, 0)
  # fiveSecondTicker = newTickInterval(5, currentTime, 0.5)
  projectProfitTicker = newTickInterval(3, currentTime, 0)
  employeeSalaryTicker = newTickInterval(12, currentTime, 1)
  occasionalTicker = newTickInterval(30, currentTime, 2)
  dayTicker = newTickInterval(Day, currentTime, 0)
  playerCount = 0
  businessCount = 0
  employeeCount = 0

let
  db = psqlSingle
  valkey = valkeySingle

randomize()

proc computeGameLogic* =
  while true:
    sleep(TickRateInMs)
    lastTime = currentTime
    currentTime = epochTime()
    stdout.eraseLine()
    stdout.writeLine "Epoch time: " & $currentTime
    stdout.eraseLine()
    stdout.writeLine "  Delta: " & $(currentTime - lastTime)
    stdout.eraseLine()
    stdout.writeLine "  Deviation from tickrate: " & $(currentTime - lastTime - (TickRateInMs / 1000))
    stdout.eraseLine()
    stdout.writeLine "Player count: " & $playerCount
    stdout.eraseLine()
    stdout.writeLine "Business count: " & $businessCount
    stdout.eraseLine()
    stdout.writeLine "Employee count (Pl.* " & $EmployeeToPlayerRatio & "): " & $employeeCount
    stdout.cursorUp(6)
    stdout.flushFile

    if occasionalTicker.elapsed(currentTime):
      occasionalTicker.tick(currentTime)
      discard valkey.command("SET", "topPlayers", getTopPlayers(db))

    if dayTicker.elapsed(currentTime):
      dayTicker.tick(currentTime)

      let newMotd = getRandomMotd()
      discard valkey.command("SET", "currentMotd", newMotd)
      # echo "\nNew MOTD: " & newMotd

    if employeeSalaryTicker.elapsed(currentTime):
      employeeSalaryTicker.tick(currentTime)
      var
        playerQuery = Player()
        businessQuery = @[Business()]
        employeeQuery = @[Employee()]
      # TODO/idea: Instead of loading all of it at once, utilise LIMIT and OFFSET
      # to manage queries in chunks.
      db.selectAll(businessQuery)
      for business in businessQuery:
        if not db.exists(Employee, "workplace = $1", business.id): continue
        # Businesses always have an owner, that could change though
        db.select(playerQuery, "id = $1", business.owner)
        db.select(employeeQuery, "workplace = $1", business.id)
        for emp in employeeQuery:
          playerQuery.money -= emp.salary
          emp.loyalty = min(emp.loyalty + 1, 10000)
          emp.experience = min(emp.experience + 1, 30000)
          emp.salary += int32(max(float64(emp.salary) * 0.01, 1))
          # emp.salary += 1
          var empvar = emp # Mutable version
          db.update(empvar)
        # db.update(employeeQuery) # Psql raises error, I believe this might be a bug with Norm
        db.update(playerQuery)
        var ws: WebSocket
        withLockedWs:
          if websocketsById.hasKey(playerQuery.id):
            ws = websocketsById[playerQuery.id]
          else: continue
        ws.send("m=" & $playerQuery.money)
        for emp in employeeQuery:
          ws.send("wempsal=" & colonSerialize(
            get(emp.workplace), emp.id, emp.salary
          ))

    if projectProfitTicker.elapsed(currentTime):
      projectProfitTicker.tick(currentTime)

      var counts = ModelCounts()
      db.rawSelect("""
        SELECT
          (SELECT COUNT(*) FROM "Players") AS players,
          (SELECT COUNT(*) FROM "Businesses") AS businesses,
          (SELECT COUNT(*) FROM "Employees") AS employees
      """, counts)
    
      playerCount = counts.players
      businessCount = counts.businesses
      employeeCount = counts.employees

      if playerCount == 0: continue
      
      # db.exec(sql"""
      #   UPDATE "Players" AS ply SET money = money + (
      #     SELECT  COUNT(*) FROM "Employees" AS emp WHERE emp.workplace IN (
      #       SELECT id FROM "Businesses" AS biz WHERE owner = ply.id
      #     )
      #   ) * 2;
      # """)
      
      # Adding employees based on player count
      if employeeCount < playerCount * EmployeeToPlayerRatio:
        var newEmployees: seq[Employee]
        for _ in employeeCount+1..playerCount*EmployeeToPlayerRatio:
          assert MaleLastNameCount == FemaleLastNameCount, "Last name counts differ, either fix the discrepency or fix the randomiser"
          let
            gender = sample(["M", "F"])
            firstname =
              if gender == "M": rand(0..MaleFirstNameCount - 1)
              else: rand(0..FemaleFirstNameCount - 1)
            lastname = rand(0..MaleLastNameCount - 1)
          newEmployees.add Employee(
            gender: newPaddedStringOfCap[1](gender),
            firstname: int16(firstname),
            lastname: int16(lastname),
            proficiency: rand(EmployeeProficiency),
            experience: int16(rand(5..15))
          )
        db.insert(newEmployees)

      if businessCount == 0: continue

      # Profits!
      var
        playerQuery = Player()
        businessQuery = @[Business()]
        employeeQuery = @[Employee()]
        projectQuery = @[Project()]
      # TODO/idea: Instead of loading all of it at once, utilise LIMIT and OFFSET
      # to manage queries in chunks.
      db.selectAll(businessQuery)
      for business in businessQuery:
        if not db.exists(Employee, "workplace = $1", business.id): continue
        if not db.exists(Project, "business = $1 AND active = TRUE", business.id): continue
        # Businesses always have an owner, that could change though
        db.select(playerQuery, "id = $1", business.owner)
        db.select(employeeQuery, "workplace = $1", business.id)
        db.select(projectQuery, "business = $1 AND active = TRUE", business.id)
        # let employeeCount = employeeQuery.len
        # var projIndex = 1
        for proj in projectQuery:
          # if (employeeCount < (projIndex * (projIndex + 1)) div 2): break
          # projIndex += 1
          case proj.project:
          of BusinessProject.serverHosting:
            for emp in employeeQuery:
              case emp.proficiency:
              of EmployeeProficiency.taxpayer:
                proj.quality += 2
              of EmployeeProficiency.hungry:
                proj.quality += 2
              of EmployeeProficiency.vimuser:
                proj.quality += 3
              of EmployeeProficiency.slacker:
                proj.quality += 2
              of EmployeeProficiency.grandparent:
                proj.quality += 1
              of EmployeeProficiency.mathematician:
                proj.quality += 2

          of BusinessProject.iotHardware:
            for emp in employeeQuery:
              case emp.proficiency:
              of EmployeeProficiency.taxpayer:
                proj.quality += 2
              of EmployeeProficiency.hungry:
                proj.quality += 1
              of EmployeeProficiency.vimuser:
                proj.quality += 3
              of EmployeeProficiency.slacker:
                proj.quality += 1
              of EmployeeProficiency.grandparent:
                proj.quality += 1
              of EmployeeProficiency.mathematician:
                proj.quality += 2

          of BusinessProject.jsFramework:
            for emp in employeeQuery:
              case emp.proficiency:
              of EmployeeProficiency.taxpayer:
                proj.quality += 2
              of EmployeeProficiency.hungry:
                proj.quality += 1
              of EmployeeProficiency.vimuser:
                proj.quality += 4
              of EmployeeProficiency.slacker:
                proj.quality += 3
              of EmployeeProficiency.grandparent:
                proj.quality += 1
              of EmployeeProficiency.mathematician:
                proj.quality += 1

          of BusinessProject.cupcakes:
            for emp in employeeQuery:
              case emp.proficiency:
              of EmployeeProficiency.taxpayer:
                proj.quality += 2
              of EmployeeProficiency.hungry:
                proj.quality += 3
              of EmployeeProficiency.vimuser:
                proj.quality += 1
              of EmployeeProficiency.slacker:
                proj.quality += 1
              of EmployeeProficiency.grandparent:
                proj.quality += 3
              of EmployeeProficiency.mathematician:
                proj.quality += 2

          of BusinessProject.pizza:
            for emp in employeeQuery:
              case emp.proficiency:
              of EmployeeProficiency.taxpayer:
                proj.quality += 2
              of EmployeeProficiency.hungry:
                proj.quality += 4
              of EmployeeProficiency.vimuser:
                proj.quality += 2
              of EmployeeProficiency.slacker:
                proj.quality += 1
              of EmployeeProficiency.grandparent:
                proj.quality += 3
              of EmployeeProficiency.mathematician:
                proj.quality += 1

          of BusinessProject.piradzini:
            for emp in employeeQuery:
              case emp.proficiency:
              of EmployeeProficiency.taxpayer:
                proj.quality += 2
              of EmployeeProficiency.hungry:
                proj.quality += 3
              of EmployeeProficiency.vimuser:
                proj.quality += 1
              of EmployeeProficiency.slacker:
                proj.quality += 2
              of EmployeeProficiency.grandparent:
                proj.quality += 4
              of EmployeeProficiency.mathematician:
                proj.quality += 1

          of BusinessProject.furniture:
            for emp in employeeQuery:
              case emp.proficiency:
              of EmployeeProficiency.taxpayer:
                proj.quality += 2
              of EmployeeProficiency.hungry:
                proj.quality += 1
              of EmployeeProficiency.vimuser:
                proj.quality += 3
              of EmployeeProficiency.slacker:
                proj.quality += 1
              of EmployeeProficiency.grandparent:
                proj.quality += 2
              of EmployeeProficiency.mathematician:
                proj.quality += 3

          of BusinessProject.barns:
            for emp in employeeQuery:
              case emp.proficiency:
              of EmployeeProficiency.taxpayer:
                proj.quality += 2
              of EmployeeProficiency.hungry:
                proj.quality += 2
              of EmployeeProficiency.vimuser:
                proj.quality += 1
              of EmployeeProficiency.slacker:
                proj.quality += 1
              of EmployeeProficiency.grandparent:
                proj.quality += 3
              of EmployeeProficiency.mathematician:
                proj.quality += 4

          of BusinessProject.figurines:
            for emp in employeeQuery:
              case emp.proficiency:
              of EmployeeProficiency.taxpayer:
                proj.quality += 2
              of EmployeeProficiency.hungry:
                proj.quality += 2
              of EmployeeProficiency.vimuser:
                proj.quality += 1
              of EmployeeProficiency.slacker:
                proj.quality += 1
              of EmployeeProficiency.grandparent:
                proj.quality += 2
              of EmployeeProficiency.mathematician:
                proj.quality += 2

          # else: discard
          playerQuery.money += proj.quality
          var projvar = proj
          db.update(projvar)

        # db.update(projectQuery) # Another bug with bulk updating
        db.update(playerQuery)
        var ws: WebSocket
        withLockedWs:
          if websocketsById.hasKey(playerQuery.id):
            ws = websocketsById[playerQuery.id]
          else: continue
        ws.send("m=" & $playerQuery.money)
        for proj in projectQuery:
          ws.send("wprojquality=" & colonSerialize(proj.business, proj.id, proj.quality))
