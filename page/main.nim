import dekao
import "sprae.nim"

let page = render:
  say: "<!DOCTYPE html>"
  html:
    head:
      script:
        src "pow.js"
        tdefer "uhuh"
      script:
        src "script.js"
        tdefer "yep"
      title: say "Business Road"
    body:
      h1: say "Hello, Economy!"
      q: sText "motd"
      p:
        sIf "1 != 1"
        say "if youre seeing this, sprae didnt work"
      tdiv:
        sWith "{input: ''}"
        input:
          sValue "input"
        pre:
          sText "input == '' ? '\\n' : hash(input)"
      button:
        # sWith "{val: ''}"
        sOn "click", "() => {pingServerCounter()}"
        sText "'Valkey counter: ' + serverCount"

writeFile "dist/index.html", page
echo "'index.html' written!"
