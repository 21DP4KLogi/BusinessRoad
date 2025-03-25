import std/json

const
  MaleFirstNameCount* = 23
  MaleLastNameCount* = 16
  FemaleFirstNameCount* = 16
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
