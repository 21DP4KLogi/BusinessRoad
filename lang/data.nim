import std/json

const
  MaleFirstNameCount* = 40
  MaleLastNameCount* = 25
  FemaleFirstNameCount* = 22
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
