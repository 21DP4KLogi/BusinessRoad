import "../lang"/[data]
writeFile "dist/langdata.json", data.LangDataJson
echo "'langdata.json' written!"

import "../api/models.nim"
writeFile "dist/modeldata.json", models.enumJson
echo "'modeldata.json' written!"

import "html.nim"
writeFile "dist/public/index.html", html.main
echo "'index.html' written!"
