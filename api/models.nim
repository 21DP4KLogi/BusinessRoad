import norm/[types, model, pragmas]
# import std/[options, json]

type
  Player* = ref object of Model
    code*: PaddedStringOfCap[8]
    money*: int32

func newPlayer*(code: string = "", money: int32 = 0): Player =
  Player(
    code: newPaddedStringOfCap[8](code),
    money: money
  )
