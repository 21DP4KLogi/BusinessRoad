import norm/[types, model]
import std/[options, json]

proc `%`*(psoc: PaddedStringOfCap): JsonNode = %($psoc)
proc `%`*(soc: StringOfCap): JsonNode = %($soc)

type
  Player* = ref object of Model
    code*: PaddedStringOfCap[8] = newPaddedStringOfCap[8]("")
    authToken*: Option[PaddedStringOfCap[12]] = none PaddedStringOfCap[12]
    money*: int32 = 0
    gender*: PaddedStringOfCap[1] = newPaddedStringOfCap[1]("M")
    firstname*: int16 = 0
    lastname*: int16 = 0
