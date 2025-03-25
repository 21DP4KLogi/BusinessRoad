import std/[tables]
import "../lang/data.nim"

export data

const langs* = { # This does seem to read at compile time as intended, as I could find the jsons' texts in the binary
  "en": readFile("./dist/lang/en.json"),
  "lv": readFile("./dist/lang/lv.json"),
}.toTable
