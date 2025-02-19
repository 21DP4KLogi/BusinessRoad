import nimcrypto
import std/[sysrand, strutils]
import "valkey.nim" as _

let valkey = valkeyPool

const
  Base64digits* = {'a'..'z', 'A'..'Z', '0'..'9', '+', '/'}
  UppercaseHexDigits* = {'0'..'9', 'A'..'F'} # strutils' HexDigits contains both upper and lower case, but lower is not expected here
  SaltByteCount* = 5
  SaltHexLength* = SaltByteCount * 2
  HashSignatureHexLenght* = 64
when defined(powNumberAlwaysZero):
  const MaxSecretNumber = 0
else:
  const MaxSecretNumber = 1_000_000

proc containsAnythingBut*(s: string,  sub: set[char]): bool =
  return s.contains(AllChars - sub)

# Utilizes std/sysrand, which, while not audited, is supposed to be secure.
# Base64 would be more concise, but im too lazy to account for the 3:4 bit ratio.
proc secureRandomHexadecimal*(length: int): string =
  let randomBytes = urandom(length)
  return randomBytes.toHex

proc secureRandomNumber*(): uint =
  let randomBytes = urandom(4)
  var random32bitNumber: uint32
  for i in 0..(randomBytes.len - 1):
    random32bitNumber += randomBytes[i]
    random32bitNumber = random32bitNumber shl 8
  return random32bitNumber mod MaxSecretNumber

proc generatePowChallenge*: string =
  let
    serverKey = valkey.command("GET", "powSignatureKey").to(string)
    salt = secureRandomHexadecimal(SaltByteCount)
    secretNumber = when MaxSecretNumber == 0: 0 else: secureRandomNumber()
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
