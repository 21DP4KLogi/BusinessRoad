import nimcrypto/sha2

proc hash(input: cstring): cstring {.exportc.} =
  return cstring($sha256.digest($input))

proc solve(hash, salt: cstring, maxInt: int): int {.exportc.} =
  let strHash = $hash
  let strSalt = $salt
  for i in 1..maxInt:
    # NOTE: requires UPPERCASE hash input
    if $sha256.digest(strSalt & $i) == strHash:
      return i
  return 0;
