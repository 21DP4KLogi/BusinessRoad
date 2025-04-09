import std/[os, times, random, terminal]
import "databases.nim"
import "lang_base.nim"
import "motd.nim"

const
  TickRateInMs = 1000
  EmployeeToPlayerRatio = 5

const
  Second = 1
  Minute = 60 * Second
  Hour = 60 * Minute
  Day = 24 * Hour

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

# var lastMinuteTick, lastHourTick, lastDayTick = epochTime()

var
  currentTime = epochTime()
  lastTime = currentTime
  secondTicker = newTickInterval(1, currentTime, 0)
  dayTicker = newTickInterval(Day, currentTime, 0)
  playerCount = 0

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
    stdout.cursorUp(4)
    stdout.flushFile

    if dayTicker.elapsed(currentTime):
      dayTicker.tick(currentTime)

      let newMotd = getRandomMotd()
      discard valkey.command("SET", "currentMotd", newMotd)
      # echo "\nNew MOTD: " & newMotd

    if secondTicker.elapsed(currentTime):
      secondTicker.tick(currentTime)
    
      playerCount = db.count Player
      if playerCount == 0: continue

      let employeeCount = db.count Employee
      
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
