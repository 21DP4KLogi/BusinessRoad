import norm/[types, model, postgres]
import std/[options, json]

proc `%`*(psoc: PaddedStringOfCap): JsonNode = %($psoc)
proc `%`*(soc: StringOfCap): JsonNode = %($soc)

template dbProcsForEnum(enumtype: typedesc) =
  func dbType*(T: typedesc[enumtype]): string = "SMALLINT"
  func dbValue*(val: enumtype): DbValue = dbValue(int16(val))
  proc to*(dbVal: DbValue, T: typedesc[enumtype]): enumtype = dbVal.i.enumtype

type
  EmployeeProficiency* = enum
    taxpayer,
    hungry,
    vimuser,

  BusinessField* = enum
    eikt,
    baking,

  BusinessProject* = enum
    serverHosting,
    iotHardware,
    jsFramework,
    cupcakes,

dbProcsForEnum EmployeeProficiency
dbProcsForEnum BusinessField
dbProcsForEnum BusinessProject

type
  Player* = ref object of Model
    code*: PaddedStringOfCap[8] = newPaddedStringOfCap[8]("")
    authToken*: Option[PaddedStringOfCap[12]] = none PaddedStringOfCap[12]
    money*: int32 = 0
    gender*: PaddedStringOfCap[1] = newPaddedStringOfCap[1]("M")
    firstname*: int16 = 0
    lastname*: int16 = 0

  Business* = ref object of Model
    owner*: Player = Player()
    field*: BusinessField = BusinessField.eikt

  Employee* = ref object of Model
    workplace*: Option[Business] = none Business
    salary*: int32 = 0
    proficiency*: EmployeeProficiency = EmployeeProficiency.taxpayer
    gender*: PaddedStringOfCap[1] = newPaddedStringOfCap[1]("M")
    firstname*: int16 = 0
    lastname*: int16 = 0

  Project* = ref object of Model
    business*: Business = Business()
    Project*: BusinessProject = BusinessProject.serverHosting

  Contract* = ref object of Model
    initiator*: Business = Business()
    project*: Project = Project()
    recipient*: Option[Business] = none Business
