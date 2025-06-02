import norm/[types, model, postgres, pragmas]
import std/[options, json, sequtils, tables]

proc `%`*(psoc: PaddedStringOfCap): JsonNode = %($psoc)
proc `%`*(soc: StringOfCap): JsonNode = %($soc)

template dbProcsForEnum(enumtype: typedesc) =
  func dbType*(T: typedesc[enumtype]): string = "SMALLINT"
  func dbValue*(val: enumtype): DbValue = dbValue(int16(val))
  proc to*(dbVal: DbValue, T: typedesc[enumtype]): enumtype = dbVal.i.enumtype

func contains*(e: typedesc[enum], i: int): bool =
  int(low(e)) <= i and i <= int(high(e))

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

const availableProjects*: Table[BusinessField, set[BusinessProject]] =
  {
    eikt: {iotHardware},
    baking: {cupcakes}
  }.toTable()

proc availableProjectsJSONable: Table[string, seq[string]] =
  for k, v in availableProjects.pairs:
    result[$k] = v.toSeq().mapIt($it)

const enumJson* = $ %* {
  "EmployeeProficiency": EmployeeProficiency.mapIt($it),
  "BusinessField": BusinessField.mapIt($it),
  "BusinessProject": BusinessProject.mapIt($it),
  "AvailableProjects": availableProjectsJSONable()
}

type
  Player* {.tableName: "Players".} = ref object of Model
    code*: PaddedStringOfCap[8] = newPaddedStringOfCap[8]("")
    authToken*: Option[PaddedStringOfCap[12]] = none PaddedStringOfCap[12]
    money*: int64 = 0
    gender*: PaddedStringOfCap[1] = newPaddedStringOfCap[1]("M")
    firstname*: int16 = 0
    lastname*: int16 = 0

  Business* {.tableName: "Businesses".} = ref object of Model
    owner* {.fk: Player.}: int64 = 0
    field*: BusinessField = BusinessField.eikt

  Employee* {.tableName: "Employees".} = ref object of Model
    workplace* {.fk: Business.}: Option[int64] = none int64
    interview* {.fk: Business.}: Option[int64] = none int64
    salary*: int32 = 0
    proficiency*: EmployeeProficiency = EmployeeProficiency.taxpayer
    experience*: int16 = 0
    loyalty*: int16 = 0
    gender*: PaddedStringOfCap[1] = newPaddedStringOfCap[1]("M")
    firstname*: int16 = 0
    lastname*: int16 = 0

  Project* {.tableName: "Projects".} = ref object of Model
    business* {.fk: Business.}: int64 = 0
    project*: BusinessProject = BusinessProject.serverHosting
    quality*: int32 = 0

  Contract* {.tableName: "Contract".} = ref object of Model
    active*: bool = false
    # Initiator
    initiator* {.fk: Business.}: int64 = 0
    initiatorProject* {.fk: Project.}: Option[int64] = none int64
    initiatorAgrees*: bool = false
    initiatorPayment*: int32 = 0
    # Recipient
    recipient* {.fk: Business.}: Option[int64] = none int64
    recipientProject* {.fk: Project.}: Option[int64] = none int64
    recipientAgrees*: bool = false
    recipientPayment*: int32 = 0

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
    employees*: Table[string, frontendEmployee]
    interviewees*: Table[string, frontendEmployee]
    projects*: Table[string, frontendProject]

  frontendProject* = object
    id*: int64
    business*: int64
    project*: BusinessProject = BusinessProject.serverHosting
    quality*: int32 = 0
  #   beneficiary*: int64

  # frontendContract* = object
  #   id*: int64
  #   active*: bool = false
  #   # Initiator
  #   initiator*: int64 = 0
  #   initiatorProject*: Option[int64] = none int64
  #   initiatorAgrees*: bool = false
  #   initiatorPayment*: int32 = 0
  #   # Recipient
  #   recipient*: Option[int64] = none int64
  #   recipientProject*: Option[int64] = none int64
  #   recipientAgrees*: bool = false
  #   recipientPayment*: int32 = 0   
