import dekao
import "sprae.nim"

let authPage = render:
  input "#authInput":
    placeholder "••••••••"
    sValue "authPage.codeInput"
    maxlength "8"
  tdiv "#authmodesel":
    span ".authModeSelection":
      sText "authPage.action == 'login' ? l('login').toUpperCase() : l('login')"
      sOn "click", "() => {authPage.action = 'login'; authPage.buttonAction = loginFunc}"
    span ".authModeSelection":
      sText "authPage.action == 'register' ? l('register').toUpperCase() : l('register')"
      sOn "click", "() => {authPage.action = 'register'; authPage.buttonAction = registerFunc}"
    span ".authModeSelection":
      sText "authPage.action == 'delete' ? l('delete').toUpperCase() : l('delete')"
      sOn "click", "() => {authPage.action = 'delete'; authPage.buttonAction = deleteFunc}"
  tdiv "#authreg":
    sIf "authPage.action == 'register'"
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
  button "#authbutton":
    sText "l(authPage.action)"
    sOn "click", "() => {authPage.buttonAction()}"
    

let gamePage = render:
  p: say "wah"

let main* = render:
  say: "<!DOCTYPE html>"
  html:
    head:
      meta:
        charset "utf-8"
      script:
        src "script.js"
        tdefer "yep"
      link:
        href "style.css"
        rel "stylesheet"
      title: say "Business Road"
    body:
      tdiv "#topbar":
        span ".left":
          h1: sText "l('title')"
          q:
            sIf "loaded"
            sText "motd"
        span ".right":
          select "#langsel":
            sValue "langcode"
            option:
              say "English"
              value "en"
            option:
              say "Latviešu"
              value "lv"
          select "#themesel":
            option: say "Light"
            option: say "Dark"
            option: say "Gruvbox"
          button:
            sIf "curPage == 'game' && loaded"
            sText "l('logout')"
            sOn "click", "() => {logoutFunc()}"
          span:
            sIf "curPage == 'game' && loaded"
            sText "l('fullname', [gd.gender, gd.firstname, gd.lastname])"
      tdiv "#infobar": discard
      tdiv "#main":
        tdiv "#loading":
          sIf "!loaded"
          h3: say "Loading..."
          noscript: h3: say "or not? JavaScript seems to be disabled."
          tstyle:
            say "#authpage, #gamepage {display: none}"
        tdiv "#authpage":
          sIf "curPage == 'guest' && loaded"
          say authPage
        tdiv "#gamepage":
          sIf "curPage == 'game' && loaded"
          say gamePage
