import std/[json]

const firstnames = ["Billy", "Miller"]

const en* = $ %* {
  "title": "Business Road",
  "greeting": "Hello, [firstname.$0] [lastname]!",
  "fullname": "[firstname.$0] [lastname]",
  "logout": "Log out",
  "register": "Register",
  "login": "Log in",
  "delete": "Delete",
  "moneyIndicator": "Money: $",
  "_": {
    "firstname": firstnames,
    "lastname": "Nair"
  }
}
