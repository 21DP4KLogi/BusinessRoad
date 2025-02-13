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
  "Please lend me a light, i'll give you back 4 in the summer!",
  "Spending silver quite like salt",
  "Hey, we're millionaires!",
  "I've been working for 30 hours straight, is that enough?",
  "We have such unequal demand/supply",
  "How does a coin go into bits?",
  "First step is to dress nice if you want to make some serious money",
  "Put food on your family",
  "The government needs 7 dollars.",
  "Brought to you by today's sponsor - JustWireMeTheMoneyAlready.su",
  "EA Nasir - it's in the trade",
  "9€ Plov, 10€ bill, do the math",
  "DO NOT REDEEM",
  "Hummus, it's going places!",
]

randomize()

proc randomizeMotd*(valkey: RedisPool) =
  discard valkey.command("SET", "currentMotd", MOTDs.sample)

proc getMotd*(valkey: RedisPool): string =
  return valkey.command("GET", "currentMotd").to(string)

