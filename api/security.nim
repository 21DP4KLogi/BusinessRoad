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

func triangleNumber*(index: int): int =
  (index * (index + 1)) div 2

# Simple parameter validation
template invalidParameters*(params: seq[string], exactLen: Natural): bool =
  ("" in params) or (params.len != exactLen)

template invalidInt64*(param: string): bool =
  (param.containsAnythingBut(Digits)) or (param.len > SafeInt64Len)

template invalidInt32*(param: string): bool =
  (param.containsAnythingBut(Digits)) or (param.len > SafeInt32Len)

template invalidInt16*(param: string): bool =
  (param.containsAnythingBut(Digits)) or (param.len > SafeInt16Len)

template ownsBusiness*(player: int64, db: DbConn, businessId: int64): bool =
  db.exists(Business, "owner = $1", player)

template ownsProject*(businessId: int64, db: DbConn, projectId: int64): bool =
  db.exists(Project, "business = $1", businessId)
#
# Parameter validation
# Way too excessive, comment kept for future reference
#
# macro validateParameters*(validations: untyped) =
#   result = nnkStmtList.newTree()
#   let statementCount = validations.len
#   result.add quote do:
#     if
#       parameters.len != `statementCount` or # Using `validations.len` directly broke the AST
#       "" in parameters:
#       ws.send("ERR=Invalid")
#       return
#   var psqlEnabled = false
#   for index, val in validations.pairs:
#     val.expectLen 2 # Due to tree structure, this is not that effective
#     val.expectKind nnkCommand
#     val[0].expectKind nnkIdent
#     val[1].expectKind nnkIdent
#     let
#       validationType = val[0]
#       paramName = val[1]
#     case validationType.repr:

#       of "modelId":
#         result.add quote do:
#           if
#             parameters[`index`].containsAnythingBut(Digits) or
#             parameters[`index`].len > SafeInt64Len
#             :
#             ws.send("ERR=Invalid")
#             return
#           let `paramName`: int64 = parameters[`index`].parseInt

#       of "playerOwnedBusiness": 
#         if not psqlEnabled:
#           psqlEnabled = true
#           # result.add quote do:
#           #   psql: discard
#           # result.add nnkCall.newNimNode
#           # psqlCallNode.strVal = "psql"
#           let psqlCallNode = newNimNode(nnkCall)
#           # psqlCallNode.add newNimNode(nnkSym)
#           psqlCallNode.add newIdentNode("psql")
#           # psqlCallNode.add nnkSym.newNimNode
#           # psqlCallNode.body = newStrLitNode("psql")
#           result.add psqlCallNode
#           # echo psqlCallNode.treeRepr
#         result[^1].add quote do:
#           if
#             parameters[`index`].containsAnythingBut(Digits) or
#             parameters[`index`].len > SafeInt64Len
#             :
#             ws.send("ERR=Invalid")
#             return
#           let `paramName`: int64 = parameters[`index`].parseInt
#   echo "!===!"
#   echo result.repr
#   echo "!===!"
#   echo result.treeRepr

