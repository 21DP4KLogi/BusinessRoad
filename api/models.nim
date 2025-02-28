import norm/[types, model]
import std/options

type
  Player* = ref object of Model
    code*: PaddedStringOfCap[8]
    authToken*: Option[PaddedStringOfCap[12]]
    money*: int32

func newPlayer*(
  code: string = "",
  money: int32 = 0,
  authToken: Option[PaddedStringOfCap[12]] = none PaddedStringOfCap[12]
  ): Player =
  Player(
    code: newPaddedStringOfCap[8](code),
    money: money,
    authToken: authToken
  )
