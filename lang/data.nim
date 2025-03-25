import std/json

const
  MaleFirstNameCount* = 27
  MaleLastNameCount* = 16
  FemaleFirstNameCount* = 19
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
