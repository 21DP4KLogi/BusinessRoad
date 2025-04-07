import norm/[types, model, postgres, pragmas]
import std/[options, json, sequtils]

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

const enumJson* = $ %* {
  "EmployeeProficiency": EmployeeProficiency.mapIt($it),
  "BusinessField": BusinessField.mapIt($it),
  "BusinessProject": BusinessProject.mapIt($it)
}

type
  Player* {.tableName: "Players".} = ref object of Model
    code*: PaddedStringOfCap[8] = newPaddedStringOfCap[8]("")
    authToken*: Option[PaddedStringOfCap[12]] = none PaddedStringOfCap[12]
    money*: int32 = 0
    gender*: PaddedStringOfCap[1] = newPaddedStringOfCap[1]("M")
    firstname*: int16 = 0
    lastname*: int16 = 0

  Business* {.tableName: "Businesses".} = ref object of Model
    owner* {.fk: Player.}: int64 = 0
    field*: BusinessField = BusinessField.eikt

  Employee* {.tableName: "Employees".} = ref object of Model
    workplace* {.fk: Business.}: Option[int64] = none int64
    salary*: int32 = 0
    proficiency*: EmployeeProficiency = EmployeeProficiency.taxpayer
    gender*: PaddedStringOfCap[1] = newPaddedStringOfCap[1]("M")
    firstname*: int16 = 0
    lastname*: int16 = 0

  Project* {.tableName: "Projects".} = ref object of Model
    business* {.fk: Business.}: int64 = 0
    Project*: BusinessProject = BusinessProject.serverHosting

  Contract* {.tableName: "Contract".} = ref object of Model
    initiator* {.fk: Business.}: int64 = 0
    project* {.fk: Project.}: int64 = 0
    recipient* {.fk: Business.}: Option[int64] = none int64

type
  frontendEmployee* = object
    id*: int64
    salary*: int32
    proficiency*: EmployeeProficiency
    gender*: PaddedStringOfCap[1]
    firstname*: int16 = 0
    lastname*: int16 = 0
  
  frontendBusiness* = object
    id*: int64
    field*: BusinessField
    employees*: seq[frontendEmployee]
