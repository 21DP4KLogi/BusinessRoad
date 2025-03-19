import "data.nim"
import std/[json]

const MaleFirstNames = [
  "Alan", "Andreas",
  "Billy",
  "Christer",
  "Greg",
  "James", "Jeff", "John", "Juris",
  "Linus",
  "Miller", "Michael", "Mikhail",
  "Peter",
  "Richard",
  "Sergey", "Serhiy", "Steve",
  "Tim", "Tom",
  "Vasily",
  "Will",
  "Yuriy",
]
const FemaleFirstNames = [
  "Ada",
  "Barbara", "Bella",
  "Carol",
  "Grace",
  "Jane",
  "Kim",
  "Maria", "Miley",
  "Natasha",
  "Olga", "Olha",
  "Rachel",
  "Samantha", "Svetlana",
  "Wendy",
]

const LastNames = [
  "Balodis", "Bean",
  "Doe",
  "Griffin",
  "Klein",
  "Mamatov", "MacDonald",
  "Nair", "Nemchuk",
  "Roizman", "Rossmann", "Rowland",
  "Scott", "Sheridan", "Simpson", "Smith",
]
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
      "M": MaleFirstNames,
      "F": FemaleFirstNames
    },
    "lastname": LastNames
  }
}

assert MaleFirstNames.len == MaleFirstNameCount
assert FemaleFirstNames.len == FemaleFirstNameCount
assert LastNames.len == MaleLastNameCount
