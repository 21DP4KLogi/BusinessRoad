import dekao
import "sprae.nim"

let page = render:
  say: "<!DOCTYPE html>"
  html:
    head:
      script:
        src "script.js"
        tdefer "yep"
      script: src "pow.js"
      title: say "Business Road"
    body:
      h1: say "Hello, Economy!"
      p:
        sIf "1 != 1"
        say "if youre seeing this, sprae didnt work"
      tdiv:
        sWith "{input: ''}"
        input:
          sValue "input"
        pre:
          sText "hash(input)"

writeFile "dist/index.html", page
echo "'index.html' written!"
