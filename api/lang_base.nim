import std/[tables]
import "../lang"/[data, en, lv]

export data

const DefaultLang* = "en"

const langs* = {
  "en": en.lang,
  "lv": lv.lang,
}.toTable
