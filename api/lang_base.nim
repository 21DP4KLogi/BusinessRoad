import std/[tables]
import "../lang"/[data, en, lv]

export data

const langs* = {
  "en": en.lang,
  "lv": lv.lang,
}.toTable
