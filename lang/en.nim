import "data.nim"
import std/[json]

const MaleFirstNames = ["Billy", "John", "Miller"]
const MaleLastNames = ["Doe", "Nair", "Smith"]
const FemaleFirstNames = ["Barbara", "Jane", "Miley"]
const FemaleLastNames = ["Doe", "Nair", "Smith"]

const lang* = $ %* {
  "title": "Business Road",
  "greeting": "Hello, [firstname.$0.$1] [lastname.$0.$2]!",
  "fullname": "[firstname.$0.$1] [lastname.$0.$2]",
  "logout": "Log out",
  "register": "Register",
  "login": "Log in",
  "delete": "Delete",
  "moneyIndicator": "Money: $",
  "firstname": "[firstname.$0.$1]",
  "lastname": "[lastname.$0.$1]",
  "_": {
    "firstname": {
      "M": MaleFirstNames,
      "F": FemaleFirstNames
    },
    "lastname": {
      "M": MaleLastNames,
      "F": FemaleLastNames
    },
  }
}

assert MaleFirstNames.len == MaleFirstNameCount
assert MaleLastNames.len == MaleLastNameCount
assert FemaleFirstNames.len == FemaleFirstNameCount
assert FemaleLastNames.len == FemaleLastNameCount
