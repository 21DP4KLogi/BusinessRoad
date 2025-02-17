import nimcrypto
import std/[sysrand]
import "valkey.nim" as valkeyFile

const
  Base64digits* = {'a'..'z', 'A'..'Z', '0'..'9', '+', '/'} # Used in the server.nim file, but kept here for tidyness
  UppercaseHexDigits* = {'0'..'9', 'A'..'F'} # strutils' HexDigits contains both upper and lower case, but lower is not expected here
  SaltByteCount* = 5
  SaltHexLength* = SaltByteCount * 2
  HashSignatureHexLenght* = 64
when defined(powNumberAlwaysZero):
  const MaxSecretNumber = 0
else:
  const MaxSecretNumber = 1_000_000

# Utilizes std/sysrand, which, while not audited, is supposed to be secure.
# Base64 would be more concise, but im too lazy to account for the 3:4 bit ratio.
proc secureRandomHexadecimal*(length: int): string =
  let randomBytes = urandom(length)
  return randomBytes.toHex

proc secureRandomNumber*(): uint =
  when MaxSecretNumber == 0:
    return 0
  else:
    let randomBytes = urandom(4)
    var random32bitNumber: uint
    for i in 0..(randomBytes.len - 1):
      random32bitNumber += randomBytes[i]
      random32bitNumber = random32bitNumber shl 8
    return random32bitNumber mod MaxSecretNumber

proc generateHmacKeyForPow* =
  discard valkey.command("SET", "powSignatureKey", secureRandomHexadecimal(20))

proc generatePowChallenge*: string =
  let
    serverKey = valkey.command("GET", "powSignatureKey").to(string)
    salt = secureRandomHexadecimal(SaltByteCount)
    secretNumber = secureRandomNumber()
    hash = $sha256.digest(salt & $secretNumber)
    hashSignature = $sha256.hmac(serverKey, hash)
  return salt & ":" & hash & ":" & hashSignature

proc submitPowResponse*(salt, signature: string, secretNumber: int): bool =
  if valkey.command("SISMEMBER", "usedPowSignatures", signature).to(int) == 1:
    return false
  let serverKey = valkey.command("GET", "powSignatureKey").to(string)
  let solved = signature == $sha256.hmac(serverKey, $sha256.digest(salt & $secretNumber))
  if not solved:
    return false
  discard valkey.command("SADD", "usedPowSignatures", signature)
  return true
