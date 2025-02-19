import std/random

const MOTDs = [
  "A donation a day keeps the tax audit away!",
  "moneymoneymoneymoneymoneymoneymoneymoneymoneymoney",
  "Finest business simulator since UNDEFINED!",
  "Budget does not exceed 17 Yen",
  "Generates interest!",
  "Free (Libre) money!",
  "Hey, nice credit card number!",
  "Nice profit, aaaaand its gone!",
  "Noticeably Fungible (legal-)Tender",
  "In this economy!",
  "Whatd'ya buyin'?",
  "Making dough at the bakery",
  "INSERT QUARTER",
  "[$ @ $] <-> goods/services",
  "\";UPDATE \"Player\" SET money = 1000000 WHERE TRUE;--",
  "Please lend me a light, in the summer i'll give you back 4!",
  "Spending silver quite like salt",
  "Hey, we're millionaires!",
  "I've been working for 30 hours straight, is that enough?",
  "We have such unequal demand/supply",
  "How does a coin go into bits?",
  "First step is to dress nice if you want to make some serious money",
  "Put food on your family",
  "The Government needs 7 dollars.",
  "Brought to you by today's sponsor - freecouponscraper.su",
  "EA Nasir - it's in the trade",
  "9€ Plov, 10€ bill, do the math",
  "DO NOT REDEEM",
  "Hummus, it's going places!",
  "It costs 3,499,563.25€ to run this instance, for 12 seconds",
  "Technically not a cryptominer!",
  "Does not use Bootstrap, you have to pick that up yourself",
  "I will not buy this baked goods, it is scratched!",
  "I don't know what a steamed apple wallet is",
]

randomize()

proc getRandomMotd*: string = MOTDs.sample
