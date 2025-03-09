import dekao
import "sprae.nim"

let guestPage = render:
  input "#authInput":
    placeholder "••••••••"
    sValue "authInput"
    style "font-family: monospace; width: 8ch; display: block;"
    maxlength "8"
  button:
    sText: "l('register')"
    sOn "click", "() => {registerFunc()}"
    sProp "disabled", "authOngoing"
  button:
    sText: "l('login')"
    sOn "click", "() => {loginFunc()}"
    sProp "disabled", "authOngoing || authInput.length != 8"
  button:
    sText: "l('delete')"
    sOn "click", "() => {deleteFunc()}"
    sProp "disabled", "authOngoing || authInput.length != 8"

let gamePage = render:
  button:
    sText "l('logout')"
    sOn "click", "() => {logoutFunc()}"
  span:
    sText "l('fullname', [nameid])"
  h3: sText: "l('greeting', [nameid])"
  p:
    sText: "l('moneyIndicator') + money"

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
          sOn "click", "() => {lang = langen}"
          say "English"
        button:
          sOn "click", "() => {lang = langlv}"
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
