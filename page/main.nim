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
    sProp "disabled", "authOngoing"
  button:
    say "Delete account"
    sOn "click", "() => {deleteFunc()}"
    sProp "disabled", "authOngoing"

let gamePage = render:
  button:
    say "Logout"
    sOn "click", "() => {logoutFunc()}"
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
      p:
        sIf "1 != 1"
        say "if youre seeing this, sprae didnt work"
      tdiv:
        sIf "curPage == 'guest'"
        say guestPage
      tdiv:
        sIf "curPage == 'game'"
        say gamePage

writeFile "dist/index.html", main
echo "'index.html' written!"
