import ready
import std/random

const MOTDs = [
  "A donation a day keeps the tax audit away!",
  "moneymoneymoneymoneymoneymoneymoneymoneymoneymoney",
  "Finest business simulator since UNDEFINED!",
  "Budget does not exceed 17 Yen",
  "Generates interest!",
  "Free (as in Libre) money!",
  "Hey, nice credit card number!",
  "Nice profi- Aaaaand, its gone!",
  "Noticeably Fungible (legal-)Tender",
  "In this economy!",
  "Whatd'ya buyin'?",
  "Making dough at the bakery",
  "INSERT QUARTER",
  "[$ @ $]",
  "\";UPDATE \"User\" SET money = 1000000 WHERE TRUE;--",
]

randomize()

proc randomizeMotd*(valkey: RedisPool) =
  discard valkey.command("SET", "currentMotd", MOTDs.sample)

proc getMotd*(valkey: RedisPool): string =
  return valkey.command("GET", "currentMotd").to(string)

