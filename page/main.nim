import dekao
import "sprae.nim"

# For testing a bug with sprae's :each
let sEachBugTestArea = render:
    # Test
    tdiv:
      sWith "{show: true, list: []}"
      hr: discard
      h1: say "Test area"
      pre: sText "list"
      button:
        say "-"
        sOn "click", "() => {list.pop()}"
      button:
        say "+"
        sOn "click", "() => {list.push(list.length)}"
      button:
        say "123"
        sOn "click", "() => {list = [1, 2, 3]}"
      input:
        ttype "checkbox"
        sValue "show"
      br: discard
      select:
        sIf "show"
        size "10"
        option:
          sEach "i in list"
          sText "i"

let guestPage = render:
  tdiv "#authcodeAndButton":
    input "#authInput":
      placeholder "••••••••"
      sValue "authPage.codeInput"
      maxlength "8"
    button:
      sText "l(authPage.action)"
      sOn "click", "() => {authPage.buttonAction()}"
  # Sprae.js does not seem to directly support radio menus, so onclick used as a workaround
  span ".authModeSelection":
    input "#authRadioLogin":
      name "authCategory"
      ttype "radio"
      value "login"
      sOn "click", "() => {authPage.action = 'login'; authPage.buttonAction = loginFunc}"
    label:
      tfor "authRadioLogin"
      sText "l('login')"
  span ".authModeSelection":
    input "#authRadioRegister":
      name "authCategory"
      ttype "radio"
      value "register"
      sOn "click", "() => {authPage.action = 'register'; authPage.buttonAction = registerFunc}"
    label:
      tfor "authRadioRegister"
      sText "l('register')"
  span ".authModeSelection":
    input "#authRadioDelete":
      name "authCategory"
      ttype "radio"
      value "delete"
      sOn "click", "() => {authPage.action = 'delete'; authPage.buttonAction = deleteFunc}"
    label:
      tfor "authRadioDelete"
      sText "l('delete')"
  tdiv:
    sIf "authPage.action == 'register'"
    # pre: sText "authPage.selGender + ' ' + authPage.selFname + ' ' + authPage.selLname"
    # pre: sText "authPage.namelist('firstname')"
    br: discard # temporary spacing
    button:
      say "<->"
      sOn "click", "() => {authPage.selGender = authPage.selGender == 'M' ? 'F' : 'M'}"
    select:
      sValue "authPage.selFname"
      # sWith "{list: authPage.namelist('firstname')}"
      option:
        sEach "fname in authPage.namelist('firstname')"
        sValue "fname[0]"
        sText "fname[1]"
    select:
      sValue "authPage.selLname"
      # sWith "{list: authPage.namelist('lastname')}"
      option:
        sEach "lname in authPage.namelist('lastname')"
        sValue "lname[0]"
        sText "lname[1]"
    # say sEachBugTestArea

let gamePage = render:
  button:
    sText "l('logout')"
    sOn "click", "() => {logoutFunc()}"
  span:
    sText "l('fullname', [gd.gender, gd.firstname, gd.lastname])"
  h3: sText: "l('greeting', [gd.gender, gd.firstname, gd.lastname])"
  p:
    sText: "l('moneyIndicator') + gd.money"

let main = render:
  say: "<!DOCTYPE html>"
  html:
    head:
      meta:
        charset "utf-8"
      script:
        src "pow.js"
        tdefer "uhuh"
      script:
        src "script.js"
        tdefer "yep"
      link:
        href "style.css"
        rel "stylesheet"
      title: say "Business Road"
    body:
      h1 "#title": sText "l('title')"
      i:
        sIf "loaded"
        q:
          sText "motd"
      # TODO: improve language selector
      tdiv "#langSelection":
        button:
          sOn "click", "() => {changelangFunc('en')}"
          say "English"
        button:
          sOn "click", "() => {changelangFunc('lv')}"
          say "Latviešu"
      # input: sValue "nameid" # Debug
      hr: discard
      tdiv:
        sIf "!loaded"
        h3: say "Loading..."
        noscript: h3: say "or not? JavaScript seems to be disabled."
        tstyle:
          say "#content {display: none}"
      tdiv "#content":
        # There is probably a more efficient approach than putting each page in a div
        tdiv:
          sIf "curPage == 'guest' && loaded"
          say guestPage
        tdiv:
          sIf "curPage == 'game' && loaded"
          say gamePage

writeFile "dist/index.html", main
echo "'index.html' written!"
