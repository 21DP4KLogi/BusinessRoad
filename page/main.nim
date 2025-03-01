import dekao
import "sprae.nim"

let guestPage = render:
  input:
    placeholder "••••••••"
    sValue "authInput"
    style "font-family: monospace; width: 8ch; display: block;"
    maxlength "8"
  button:
    say "Register"
    sOn "click", "() => {registerFunc()}"
    sProp "disabled", "authOngoing"
  button:
    say "Log in"
    sOn "click", "() => {loginFunc()}"
    sProp "disabled", "authOngoing || authInput.length != 8"
  button:
    say "Delete account"
    sOn "click", "() => {deleteFunc()}"
    sProp "disabled", "authOngoing || authInput.length != 8"

let gamePage = render:
  button:
    say "Logout"
    sOn "click", "() => {logoutFunc()}"
  h3: sText: "'Hello, ' + fullName + '!'"
  p:
    sText: "'Money: $' + money"

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
      title: say "Business Road"
    body:
      h1: say "Hello, Economy!"
      q: i: sText "motd"
      hr: discard
      tdiv:
        sIf "!loaded"
        h3: say "Loading..."
        noscript: h3: say "or not? JavaScript seems to be disabled."
      tdiv:
        sIf "curPage == 'guest' && loaded"
        say guestPage
      tdiv:
        sIf "curPage == 'game' && loaded"
        say gamePage

writeFile "dist/index.html", main
echo "'index.html' written!"
