import dekao
import "sprae.nim"

let page = render:
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
      input:
        placeholder "••••••••"
        sValue "authInput"
        style "font-family: monospace; width: 8ch; display: block;"
        maxlength "8"
      button:
        say "Register"
        sOn "click", "() => {registerFunc()}"
      button:
        say "Log in"
        sOn "click", "() => {loginFunc()}"
      button:
        say "Delete account"
        sOn "click", "() => {deleteFunc()}"

writeFile "dist/index.html", page
echo "'index.html' written!"
