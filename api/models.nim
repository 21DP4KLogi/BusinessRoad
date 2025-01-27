import norm/[types, model, pragmas]
import std/[options, json]

type
  Player* = ref object of Model
    code*: PaddedStringOfCap[8]

func newPlayer*(code: string = ""): Player =
  Player(code: newPaddedStringOfCap[8](code))
