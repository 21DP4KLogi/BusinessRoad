import nimcrypto
import std/[sysrand, strutils]
import "valkey.nim" as valkeyFile

# Base64 would be more concise, but im too lazy to account for the 3:4 bit ratio
proc secureRandomHexadecimal*(length: int): string =
  let randomBytes = urandom(length)
  return randomBytes.toHex

proc generateHmacKeyForPow* =
  discard valkey.command("SET", "powSignatureKey", secureRandomHexadecimal(20))

proc generatePowChallenge*: string =
  let
    serverKey = valkey.command("GET", "powSignatureKey").to(string)
    salt = secureRandomHexadecimal(5)
    secretNumber = 3  #TODO: actually randomize this 
    hash = $sha256.digest(salt & $secretNumber)
    hashSignature = $sha256.hmac(serverKey, hash)
  return salt & ":" & hash & ":" & hashSignature

proc verifyPowResponse*(salt, signature: string, secretNumber: int): bool =
  if valkey.command("SISMEMBER", "usedPowSignatures", signature).to(int) == 1:
    return false
  let serverKey = valkey.command("GET", "powSignatureKey").to(string)
  let solved = signature == $sha256.hmac(serverKey, $sha256.digest(salt & $secretNumber))
  if not solved:
    return false
  discard valkey.command("SADD", "usedPowSignatures", signature)
  return true
