import std/[json]

const lang* = $ %* {
  "title": "Biznesa Ceļš",
  "fullname": "[firstnameNom.$0.$1] [lastnameNom.$0.$2]",
  "greeting": "Sveiki, [firstnameVoc.$0.$1] [lastnameVoc.$0.$2]!",
  "logout": "Izrakstīties",
  "register": "Reģistrēties",
  "login": "Pierakstīties",
  "delete": "Dzēst",
  "moneyIndicator": "Nauda: $",
  "firstname": "[firstnameNom.$0.$1]",
  "lastname": "[lastnameNom.$0.$1]",
  "_": {
    "firstnameNom": {
      "M": ["Bilijs", "Džons", "Millers"],
      "F": ["Barbara", "Džeina", "Mailija"]
    },
    "lastnameNom": {
      "M": ["Dou", "Nērs", "Smits"],
      "F": ["Dou", "Nēra", "Smita"]
    },
    "firstnameVoc": {
      "M": ["Bilij", "Džon", "Miller"],
      "F": ["Barbar", "Džein", "Mailij"]
    },
    "lastnameVoc": {
      "M": ["Dou", "Nēr", "Smit"],
      "F": ["Dou", "Nēr", "Smit"]
    },
  }
}
