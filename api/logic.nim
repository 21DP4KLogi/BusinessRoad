import std/[os, times, random, terminal, tables]
import "databases.nim"
import "lang_base.nim"
import "motd.nim"
import "mummy_base"
import "websocket.nim"

const
  TickRateInMs = 1000
  EmployeeToPlayerRatio = 5

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
  secondTicker = newTickInterval(1, currentTime, 0)
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

    if dayTicker.elapsed(currentTime):
      dayTicker.tick(currentTime)

      let newMotd = getRandomMotd()
      discard valkey.command("SET", "currentMotd", newMotd)
      # echo "\nNew MOTD: " & newMotd

    if secondTicker.elapsed(currentTime):
      secondTicker.tick(currentTime)

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
            proficiency = rand(EmployeeProficiency)
          newEmployees.add Employee(
            gender: newPaddedStringOfCap[1](gender),
            firstname: int16(firstname),
            lastname: int16(lastname),
            proficiency: proficiency
          )
        db.insert(newEmployees)

      if businessCount == 0: continue

      # Profits!
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
        case business.field:
        of BusinessField.eikt:
          for emp in employeeQuery:
            case emp.proficiency:
            of EmployeeProficiency.taxpayer:
              playerQuery.money += 2
            of EmployeeProficiency.hungry:
              playerQuery.money += 1
            of EmployeeProficiency.vimuser:
              playerQuery.money += 3
        of BusinessField.baking:
          for emp in employeeQuery:
            case emp.proficiency:
            of EmployeeProficiency.taxpayer:
              playerQuery.money += 2
            of EmployeeProficiency.hungry:
              playerQuery.money += 3
            of EmployeeProficiency.vimuser:
              playerQuery.money += 1
        db.update(playerQuery)
        var ws: WebSocket
        withLockedWs:
          if websocketsById.hasKey(playerQuery.id):
            ws = websocketsById[playerQuery.id]
          else: continue
        ws.send("m=" & $playerQuery.money)
