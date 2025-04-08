import std/[os, times, random]
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

var lastMinuteTick, lastHourTick, lastDayTick = epochTime()

let
  db = psqlSingle
  valkey = valkeySingle

randomize()

var debugTicker = 0

proc computeGameLogic* =
  while true:
    sleep(TickRateInMs)
    let
      currentTime = epochTime()
      secondPassed = true # Since it sleeps for a second, this will be true every loop
      minutePassed = lastMinuteTick < currentTime - Minute
      hourPassed = lastHourTick < currentTime - Hour
      dayPassed = lastDayTick < currentTime - Day
    debugTicker += 1
    stdout.write "\rDebug ticker: " & $debugTicker
    stdout.flushFile

    if dayPassed:
      lastDayTick = currentTime

      let newMotd = getRandomMotd()
      discard valkey.command("SET", "currentMotd", newMotd)
      echo "\nNew MOTD: " & newMotd
    
    let playerCount = db.count Player
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
