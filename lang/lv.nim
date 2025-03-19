import "data.nim"
import "utils.nim"
import std/[json, sugar]

const MaleFirstNames = [
# Nominative, Vocative
  "Alans", "Alan",
  "Andreas", "Andreas",
  "Bilijs", "Bilij",
  "Kristers", "Krister",
  "Gregs", "Greg",
  "Džeims", "Džeims",
  "Džefs", "Džef",
  "Džons", "Džon",
  "Juris", "Juri",
  "Līnuss", "Līnus",
  "Millers", "Miller",
  "Maikls", "Maikl",
  "Mihails", "Mihail",
  "Pēteris", "Pēter",
  "Ričards", "Ričard",
  "Sergejs", "Sergej",
  "Serhijs", "Serhij",
  "Stīvs", "Stīv",
  "Tims", "Tim",
  "Toms", "Tom",
  "Vasilijs", "Vasilij",
  "Vils", "Vil",
  "Jurijs", "Jurij",
]

# Note: In Latvian, feminine words "usually" match in Nominative and Vocative.
# Source: https://www.uzdevumi.lv/p/latviesu-valoda-pec-skola2030-paraugprogrammas/8-klase/ka-valoda-atklaj-savstarpejas-attiecibas-56742/vardi-segvardi-iesaukas-un-milvardini-tu-vai-jus-98726/re-b0c41020-eda5-43ed-ab41-a5b7b6ba624f
# Accessed 2025 March 19th

const FemaleFirstNames = [
# Nominative/Vocative
  "Ada",
  "Barbara", "Bella",
  "Kerola",
  "Greisa",
  "Džeina",
  "Kima",
  "Marija", "Mailija",
  "Nataša",
  "Olga", "Olha",
  "Reičela",
  "Samanta", "Svetlana",
  "Vendija",
]

const LastNames = [ # Combined since they will be equivalents
# M Nom, M Voc, F Nom/Voc
  "Balodis", "Balodi", "Balode",
  "Bīns", "Bīn", "Bīna",
  "Dou", "Dou", "Dou", # D'oh!
  "Grifins", "Grifin", "Grifina",
  "Kleins", "Klein", "Kleina",
  "Mamatovs", "Mamatov", "Mamatova",
  "Makdonalds", "Makdonald", "Makdonalda",
  "Nērs", "Nēr", "Nēra",
  "Nemčuks", "Nemčuk", "Nemčuka",
  "Roizmens", "Roizmen", "Roizmena",
  "Rosmens", "Rosmen", "Rosmena",
  "Roulends", "Roulend", "Roulenda",
  "Skots", "Skot", "Skota",
  "Šeridans", "Šeridan", "Šeridana",
  "Simsons", "Simson", "Simsone",
  "Smits", "Smit", "Smita",
]

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
      "M": column(MaleFirstNames, 1, 2),
      "F": FemaleFirstNames
    },
    "lastnameNom": {
      "M": column(LastNames, 1, 3),
      "F": column(LastNames, 3, 3)
    },
    "firstnameVoc": {
      "M": column(MaleFirstNames, 2, 2),
      "F": FemaleFirstNames
    },
    "lastnameVoc": {
      "M": column(LastNames, 2, 3),
      "F": column(LastNames, 3, 3)
    },
  }
}

assert MaleFirstNames.len == MaleFirstNameCount * 2
assert FemaleFirstNames.len == FemaleFirstNameCount
assert LastNames.len == MaleLastNameCount * 3
