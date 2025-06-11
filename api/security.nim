import nimcrypto
import std/[sysrand, strutils, base64, math, macros]
import "databases.nim"
import "cookies.nim"

export cookies

const
  Base64digits* = {'a'..'z', 'A'..'Z', '0'..'9', '+', '/'}
  UppercaseHexDigits* = {'0'..'9', 'A'..'F'} # strutils' HexDigits contains both upper and lower case, but lower is not expected here
  SaltByteCount* = 5
  SaltHexLength* = SaltByteCount * 2
  HashSignatureHexLenght* = 64
  MaxSecretNumber =
    when defined(powNumberAlwaysZero): 0
    else: 1_000_000
  MaxSecretNumberDigitCount* = 7
  AuthTokenByteCount* = 9
  AuthTokenBase64Length* = int(ceil(AuthTokenByteCount + (AuthTokenByteCount / 3)))
  # These have 1 less digit than the int limit
  SafeInt16Len* = 4
  SafeInt32Len* = 9
  SafeInt64Len* = 18

# Concatenates all given strings with ':' as separator
proc colonSerialize*(data: varargs[string, `$`]): string =
  for str in data:
    result.addSep ":"
    result.add str

# proc hasValidAuthCookie*(headers: HttpHeaders): bool =
#   let reqCookies = parseCookies headers["Cookie"]
#   if reqCookies.hasKey("a"):
#     let authCookie = reqCookies["a"]
#     psql:
#       return db.exists(Player, "authToken = $1", authCookie)

# proc getAuthCookie*(headers: HttpHeaders): string =
#   let reqCookies = parseCookies headers["Cookie"]
#   if reqCookies.hasKey("a"):
#     return reqCookies["a"]
#   else:
#     return ""

# proc authCookieValid*(cookie: string): bool =
#   if cookie == "": return false
#   psql:
#     return db.exists(Player, "authToken = $1", cookie)

proc containsAnythingBut*(s: string, sub: set[char]): bool =
  return s.contains(AllChars - sub)

# Utilizes std/sysrand, which, while not audited, is supposed to be secure.
proc secureRandomHexadecimal*(bytes: int): string =
  return toHex urandom(bytes)

proc secureRandomBase64*(bytes: int): string =
  return base64.encode urandom(bytes)

proc secureRandomNumber*(): uint =
  let randomBytes = urandom(4)
  var random32bitNumber: uint32
  for i in 0..(randomBytes.len - 1):
    random32bitNumber += randomBytes[i]
    random32bitNumber = random32bitNumber shl 8
  return random32bitNumber mod MaxSecretNumber

proc generatePowChallenge*(valkey: RedisConn): string =
  let
    serverKey = valkey.command("GET", "powSignatureKey").to(string)
    salt = secureRandomHexadecimal(SaltByteCount)
    secretNumber = when MaxSecretNumber == 0: 0 else: secureRandomNumber()
    hash = $sha256.digest(salt & $secretNumber)
    hashSignature = $sha256.hmac(serverKey, hash)
  return colonSerialize(salt, hash, hashSignature)

proc verifyPowResponse*(valkey: RedisPool, salt, signature: string, secretNumber: int): bool =
  if valkey.command("SISMEMBER", "usedPowSignatures", signature).to(int) == 1:
    return false
  let serverKey = valkey.command("GET", "powSignatureKey").to(string)
  let solved = signature == $sha256.hmac(serverKey, $sha256.digest(salt & $secretNumber))
  if not solved:
    return false
  return true

template submitPowResponse*(valkey: RedisPool, signature: string) =
  discard valkey.command("SADD", "usedPowSignatures", signature)

#
# Parameters
#
# type
#   ParamValidationType* = enum
#     modelId

  # ParamValidation = object
  #   name: Id
  #   validation: ParamValidationType


# template `is`*(name: untyped, index: int, validation: ParamValidations) =
#   let name {.inject.} = parameters[index]

# template validate*(params: seq[string], validations: varargs[untyped]): void =
#   if params.len != validations.len:
#     ws.send("ERR=Invalid")
#     return
#   validations

# template iss*(name: untyped, validation: ParamValidationType) =
#   (name.repr, validation)

# template modelId*(name: untyped) =
#   let name {.inject.} = 123

# template validateIndividualParam(name: untyped, validation: untyped) =

# template validateParameters*(validations: typed) =
#   echo "Wahoo"
#   validations
#   echo "Thats all folks!"

macro validateParameters*(validations: untyped) =
  result = nnkStmtList.newTree()
  let statementCount = validations.len
  result.add quote do:
    if
      parameters.len != `statementCount` or # Using `validations.len` directly broke the AST
      "" in parameters:
      ws.send("ERR=Invalid")
      return
  for index, val in validations.pairs:
    val.expectLen 2 # Due to tree structure, this is not that effective
    val.expectKind nnkCommand
    val[0].expectKind nnkIdent
    val[1].expectKind nnkIdent
    let
      validationType = val[0]
      paramName = val[1]
    case validationType.repr:
    of "modelId": result.add quote do:
      if
        parameters[`index`].containsAnythingBut(Digits) or
        parameters[`index`].len > SafeInt64Len
        :
        ws.send("ERR=Invalid")
        return
      let `paramName`: int64 = parameters[`index`].parseInt
    # echo $index & " === " & val.treeRepr
  echo "!===!"
  echo result.repr
  # echo "!===!"
  # echo result.treeRepr

# macro validateParameters*(validations: untyped #[static[varargs[tuple[name: string, validation: ParamValidationType]]] ]#) =
#   result = nnkStmtList.newTree()
#   for i, val in validations.pairs:
#     let
#       validationType = val[0]
#       varName = val[1]
#     result.add quote do:
#       let `varName`: int = 5
#   echo result.treeRepr

  # for val in validations:
    # echo val.kind
  # result = quote do:
  #   dumpTree:
  #     `validations`
  # result = nnkStmtList.newTree()
  # result.add quote do:
  #   if parameters.len != `validations.len`:
  #     ws.send("ERR=Invalid")
  #     return
  # for index, val in validations.pairs:
  #   dumpTree:
  #     val
    # case val.validation:
    # of modelId:
    #   result.add quote do:
    #     let `val.name` = parameters[`index`]
