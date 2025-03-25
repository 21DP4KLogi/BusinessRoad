import "data.nim"
import std/[json, tables]
import "parsedcsv.nim"

# There might be cases with foreign names where the last names would be split up,
# e.g. transliterating a feminine lastname from another language, but I currently
# don't have those, and implementing them as such would be optional.

const lang* = $ %* {
  "title": "Business Road",
  "greeting": "Hello, [firstname.$0.$1] [lastname.$2]!",
  "fullname": "[firstname.$0.$1] [lastname.$2]",
  "logout": "Log out",
  "register": "Register",
  "login": "Log in",
  "delete": "Delete",
  "moneyIndicator": "Money: $",
  "firstname": "[firstname.$0.$1]",
  "lastname": "[lastname.$1]",
  "_": {
    "firstname": {
      "M": namesCsv["en-m-fn"],
      "F": namesCsv["en-f-fn"]
    },
    "lastname": namesCsv["en-ln"]
  }
}

assert namesCsv["en-m-fn"].len == MaleFirstNameCount, "Lenght: " & $namesCsv["en-m-fn"].len
assert namesCsv["en-f-fn"].len == FemaleFirstNameCount, "Lenght: " & $namesCsv["en-f-fn"].len
assert namesCsv["en-ln"].len == MaleLastNameCount, "Lenght: " & $namesCsv["en-ln"].len
