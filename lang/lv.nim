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
  "_": {
    "firstnameNom": {
      "M": ["Bilijs", "Millers"],
      "F": ["Barbara", "Mailija"]
    },
    "lastnameNom": {
      "M": ["Nērs"],
      "F": ["Nēra"]
    },
    "firstnameVoc": {
      "M": ["Bilij", "Miller"],
      "F": ["Barbar", "Mailij"]
    },
    "lastnameVoc": {
      "M": ["Nēr"],
      "F": ["Nēr"]
    },
    # "M": {
    #   "firstnameNom": ["Bilijs", "Millers"],
    #   "lastnameNom": ["Nērs"],
    #   "firstnameVoc": ["Bilij", "Miller"],
    #   "lastnameVoc": ["Nēr"],
    # },
    # "F": {
    #   "firstnameNom": ["Barbara", "Mailija"],
    #   "lastnameNom": ["Nēra"],
    #   "firstnameVoc": ["Barbar", "Mailij"],
    #   "lastnameVoc": ["Nēr"],
    # }
  }
}
