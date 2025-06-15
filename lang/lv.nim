import "data.nim"
import std/[json, tables]
import "parsedcsv.nim"

# Note: In Latvian, feminine words "usually" match in Nominative and Vocative.
# Source: https://www.uzdevumi.lv/p/latviesu-valoda-pec-skola2030-paraugprogrammas/8-klase/ka-valoda-atklaj-savstarpejas-attiecibas-56742/vardi-segvardi-iesaukas-un-milvardini-tu-vai-jus-98726/re-b0c41020-eda5-43ed-ab41-a5b7b6ba624f
# Accessed 2025 March 19th

const lang* = $ %* {
  "langcode": "lv",
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
  "businessField": "[businessField.$0]",
  "startBusiness": "Dibināt jaunu biznesu",
  "proficiency": "[employeeProficiency.$1.$0]",
  "hireEmp": "Pieņemt",
  "fireEmp": "Atlaist",
  "suggestSalary": "Ieteikt algu",
  "findEmployees": "Atrast darbiniekus",
  "startBusinessCost": "Dibināt biznesu par 5000$",
  "startNewProject": "Sākt jaunu projektu",
  "businessProject": "[businessProject.$0]",
  "colortheme": "[colortheme.$0]",
  "authmsg": "[authmsg.$0]",
  "interviewees": "Darba meklētāji",
  "employees": "Darbinieki",
  "projects": "Projekti",
  "_": {
    "firstnameNom": {
      "M": namesCsv["lv-m-fn-nom"],
      "F": namesCsv["lv-f-fn-nomvoc"]
    },
    "firstnameVoc": {
      "M": namesCsv["lv-m-fn-voc"],
      "F": namesCsv["lv-f-fn-nomvoc"]
    },
    "lastnameNom": {
      "M": namesCsv["lv-m-ln-nom"],
      "F": namesCsv["lv-f-ln-nomvoc"]
    },
    "lastnameVoc": {
      "M": namesCsv["lv-m-ln-voc"],
      "F": namesCsv["lv-f-ln-nomvoc"]
    },
    "businessField": {
      "eikt": "EIKT",
      "baking": "Cepšana",
    },
    "businessProject": {
      "serverHosting": "Serveru hostings",
      "iotHardware": "IoT aparatūra",
      "jsFramework": "JS ietvars",
      "cupcakes": "Kūciņas",
    },
    "employeeProficiency": {
      "M": {
        "taxpayer": "Nodokļu maksātājs",
        "hungry": "Izsalcis",
        "vimuser": "Vim lietotājs",
      },
      "F": {
        "taxpayer": "Nodokļu maksātāja",
        "hungry": "Izsalkusi",
        "vimuser": "Vim lietotāja",
      }
    },
    "colortheme": {
      "light": "Gaišs",
      "dark": "Tumšs",
      "gruvbox": "Gruvbox",
    },
    "authmsg": {
      "login": "Ievadiet savu autentifikācijas kodu, lai pierakstītos.",
      "register": "Izvēlaties sava tēla bio un reģistrējieties.",
      "delete": "Ievadiet savu autentifikācijas kodu, lai dzēstu savu kontu.",
      "registersuccess": "Konts veiksmīgi reģistrēts!",
      "deletesuccess": "Konts veiksmīgi izdzēsts!",
      "usernotfound": "Netika atrasts konts ar doto lietotāja kodu.",
      "mustbe8chars": "Kodam ir jābūt tieši 8 rakstzīmēm garam.",
      "invalidchars": "Kods var saturēt tikai angļu alfabēta burtus A-Z (lielos un mazos burtus), ciparus un zīmes '+' un '/'",
    },
  }
}

assert namesCsv["lv-m-fn-nom"].len == MaleFirstNameCount, "Lenght: " & $namesCsv["lv-m-fn-nom"].len
assert namesCsv["lv-f-fn-nomvoc"].len == FemaleFirstNameCount, "Lenght: " & $namesCsv["lv-f-fn-nomvoc"].len
assert namesCsv["lv-m-ln-voc"].len == MaleLastNameCount, "Lenght: " & $namesCsv["lv-m-ln-voc"].len
