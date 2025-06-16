import "mummy_base.nim"
import std/[strutils, tables, options, json]
import "security.nim"
import "databases.nim"
import "lang_base.nim"

let valkey = valkeyPool

proc getUserGameData(player: Player): JsonNode =
  var businessList: Table[string, frontendBusiness]

  psql:
    if db.exists(Business, "owner = $1", player.id):
      var businessQuery = @[Business()]
      var employeeQuery = @[Employee()]
      var projectQuery = @[Project()]
      db.select(businessQuery, "owner = $1", player.id)
      for business in businessQuery:
        var employeeList: Table[string, frontendEmployee]
        var intervieweeList: Table[string, frontendEmployee]
        var projectList: Table[string, frontendProject]
        # Employees
        if db.exists(Employee, "workplace = $1", business.id):
          db.select(employeeQuery, "workplace = $1", business.id)
          for employee in employeeQuery:
            # Currently 'frontendEmployee' and 'Employee' line up exactly, but that could change
            employeeList[$employee.id] = frontendEmployee(
              # There is probably some syntactic sugar for this
              id: employee.id,
              salary: employee.salary,
              proficiency: employee.proficiency,
              gender: employee.gender,
              firstname: employee.firstname,
              lastname: employee.lastname
            )
        # Interviewees
        if db.exists(Employee, "interview = $1", business.id):
          db.select(employeeQuery, "interview = $1", business.id)
          for employee in employeeQuery:
            intervieweeList[$employee.id] = frontendEmployee(
              id: employee.id,
              salary: employee.salary,
              proficiency: employee.proficiency,
              gender: employee.gender,
              firstname: employee.firstname,
              lastname: employee.lastname,
            )
        if db.exists(Project, "business = $1", business.id):
          db.select(projectQuery, "business = $1", business.id)
          for proj in projectQuery:
            projectList[$proj.id] = frontendProject(
              id: proj.id,
              business: proj.business,
              project: proj.project,
              quality: proj.quality,
              active: proj.active,
            )
        businessList[$business.id] = frontendBusiness(
          id: business.id,
          field: business.field,
          employees: employeeList,
          interviewees: intervieweeList,
          projects: projectList,
        )

  return %* {
    "firstname": player.firstname,
    "lastname": player.lastname,
    "money": player.money,
    "gender": player.gender,
    "businesses": businessList,
  }

get "/init":
  let reqCookies = parseCookies request.headers["Cookie"]

  var gameData: JsonNode = newJNull()
  if reqCookies.hasKey "a":
    psql:
      let authCookie = reqCookies["a"]
      # I tried to do the token length and char validation before opening the database,
      # but i couldn't do it in a neat way and is probably pointless anyways.
      if
        not authCookie.containsAnythingBut(Base64digits) and
        authCookie.len == AuthTokenBase64Length and
        db.exists(Player, "authToken = $1", authCookie):
          var playerQuery = Player()
          db.select(playerQuery, "authToken = $1", authCookie)
          gameData = getUserGameData(playerQuery)
      else:
        headers["Set-Cookie"] = makeCookie(
          "a", "",
          expires=daysForward(-1),
          path="/",
          secure=true,
          httpOnly=true,
          sameSite=Strict
        )
  
  var userLang: string
  if reqCookies.hasKey("l") and langs.hasKey(reqCookies["l"]):
    userLang = langs[reqCookies["l"]]
  else:
    userLang = langs[DefaultLang]
  
  let
    motdData = valkey.command("GET", "currentMotd").to(string)
    topPlayers = valkey.command("GET", "topPlayers").to(string)
  
  headers["Content-Type"] = "application/json"
  resp 200, $ %* {
    "gameData": gameData,
    "motd": motdData,
    "lang": userLang,
    "top": topPlayers,
  }

get "/setlang/@lang":
  let sentLang = request.pathParams["lang"]
  if not langs.hasKey(sentLang): resp 404
  if sentLang == DefaultLang:
    headers["Set-Cookie"] = makeCookie(
        "l", "",
        expires=daysForward(-1),
        path="/",
        secure=true,
        httpOnly=true,
        sameSite=Strict
    )
  else:
    headers["Set-Cookie"] = makeCookie(
        "l", sentLang,
        expires=daysForward(7),
        path="/",
        secure=true,
        httpOnly=true,
        sameSite=Strict
    )
  headers["Content-Type"] = "application/json"
  resp 200, langs[sentLang]

get "/challenge":
  headers["Content-Type"] = "text/plain"
  valkey.withConnection vk:
    resp 200, generatePowChallenge(vk)

post "/register":
  let body = request.body.split(":")
  if
    body.len != 6 or
    "" in body or
    body[0].containsAnythingBut(UppercaseHexDigits) or
    body[0].len != SaltHexLength or
    body[1].containsAnythingBut(UppercaseHexDigits) or
    body[1].len != HashSignatureHexLenght or
    body[2].containsAnythingBut(Digits) or
    body[2].len > MaxSecretNumberDigitCount or
    body[3] notin ["M", "F"] or
    body[4].containsAnythingBut(Digits) or
    body[4].len > SafeInt16Len or
    body[5].containsAnythingBut(Digits) or
    body[5].len > SafeInt32Len
    : resp 400
  let
    sentSalt = body[0]
    sentSignature = body[1]
    sentSecretNumber = body[2].parseInt
    sentGender = body[3]
    sentFName = int16(body[4].parseInt)
    sentLName = int16(body[5].parseInt)

  if sentGender == "M":
    if sentFName >= MaleFirstNameCount or sentLName >= MaleLastNameCount:
      resp 400
  else:
    if sentFName >= FemaleFirstNameCount or sentLName >= FemaleLastNameCount:
      resp 400

  if valkey.verifyPowResponse(sentSalt, sentSignature, sentSecretNumber):
    valkey.submitPowResponse(sentSignature)
    let newCode: string = secureRandomBase64(6)
    var playerQuery = Player(
      code: newPaddedStringOfCap[8](newCode),
      gender: newPaddedStringOfCap[1](sentGender),
      firstname: sentFName,
      lastname: sentLName,
      money: 10000,
    )
    psql:
      db.insert(playerQuery)
    headers["Content-Type"] = "text/plain"
    resp 200, newCode
  else:
    resp 401

post "/login":
  let body = request.body.split(":")
  if
    body.len != 4 or
    "" in body or
    body[0].len != 8 or
    body[0].containsAnythingBut(Base64digits) or
    body[1].containsAnythingBut(UppercaseHexDigits) or
    body[1].len != SaltHexLength or
    body[2].containsAnythingBut(UppercaseHexDigits) or
    body[2].len != HashSignatureHexLenght or
    body[3].containsAnythingBut(Digits) or
    body[3].len > MaxSecretNumberDigitCount
    : resp 400
  let
    sentCode = body[0]
    sentSalt = body[1]
    sentSignature = body[2]
    sentSecretNumber = body[3].parseInt
  if not valkey.verifyPowResponse(sentSalt, sentSignature, sentSecretNumber): resp 401
  valkey.submitPowResponse(sentSignature)
  psql:
    let codeValid = db.exists(Player, "code = $1", sentCode)
    if not codeValid: resp 404
    let authCookie = secureRandomBase64(AuthTokenByteCount)
    var playerQuery = Player()
    db.select(playerQuery, "code = $1", sentCode)
    playerQuery.authToken = some newPaddedStringOfCap[12](authCookie)
    db.update(playerQuery)
    headers["Set-Cookie"] = makeCookie(
      "a", authCookie,
      expires=daysForward(7),
      path="/",
      secure=true,
      httpOnly=true,
      sameSite=Strict
    )
    headers["Content-Type"] = "application/json"
    resp 200, $getUserGameData(playerQuery)

post "/delete":
  let body = request.body.split(":")
  if
    body.len != 4 or
    "" in body or
    body[0].len != 8 or
    body[0].containsAnythingBut(Base64digits) or
    body[1].containsAnythingBut(UppercaseHexDigits) or
    body[1].len != SaltHexLength or
    body[2].containsAnythingBut(UppercaseHexDigits) or
    body[2].len != HashSignatureHexLenght or
    body[3].containsAnythingBut(Digits) or
    body[3].len > MaxSecretNumberDigitCount
    : resp 400
  let
    sentCode = body[0]
    sentSalt = body[1]
    sentSignature = body[2]
    sentSecretNumber = body[3].parseInt
  if valkey.verifyPowResponse(sentSalt, sentSignature, sentSecretNumber):
    valkey.submitPowResponse(sentSignature)
    var codeValid = false
    psql:
      codeValid = db.exists(Player, "code = $1", sentCode)
      if codeValid:
        var playerQuery = Player()
        db.select(playerQuery, "code = $1", sentCode)
        db.exec(sql """
          UPDATE "Employees" SET workplace = NULL WHERE workplace IN (
            SELECT id FROM "Businesses" WHERE owner = $1
          )
        """, playerQuery.id)
        db.exec(sql """
          UPDATE "Employees" SET interview = NULL WHERE interview IN (
            SELECT id FROM "Businesses" WHERE owner = $1
          )
        """, playerQuery.id)
        db.exec(sql """
          DELETE FROM "Projects" WHERE business IN (
            SELECT id FROM "Businesses" WHERE owner = $1
          )
        """, playerQuery.id)
        db.exec(sql "DELETE FROM " & modelTableName(Business) & " WHERE owner = $1", playerQuery.id)
        db.delete(playerQuery)
        resp 204
      else:
        resp 404
  else:
    resp 401

post "/logout":
  # I'm not sure if I have to check whether the key "Cookie" exists
  let reqCookies = parseCookies request.headers["Cookie"]
  if not reqCookies.hasKey("a"): resp 401
  let authCookie = reqCookies["a"]
  if
    not authCookie.containsAnythingBut(Base64digits) and
    authCookie.len == AuthTokenBase64Length:
    psql:
      # This check might be a bit useless, will keep it for now incase of debugging
      if not db.exists(Player, "authToken = $1", authCookie): resp 404
      db.exec(sql "UPDATE " & modelTableName(Player) & " SET authToken = NULL WHERE authToken = $1", authCookie)
  headers["Set-Cookie"] = makeCookie(
    "a", "",
    expires=daysForward(-1),
    path="/",
    secure=true,
    httpOnly=true,
    sameSite=Strict
  )
  resp 200
