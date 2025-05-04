import std/[json, tables]
import "./parsedcsv.nim"

const
  MaleFirstNameCount* = namesCsv["en-m-fn"].len
  MaleLastNameCount* = static namesCsv["en-ln"].len
  FemaleFirstNameCount* = namesCsv["en-f-fn"].len
  FemaleLastNameCount* = MaleLastNameCount # Not sure if there would be a reason to differ

const LangDataJson* = $ %* {
  "F": {
    "firstname": FemaleFirstNameCount,
    "lastname": FemaleLastNameCount,
  },
  "M": {
    "firstname": MaleFirstNameCount,
    "lastname": MaleLastNameCount,
  }
}
