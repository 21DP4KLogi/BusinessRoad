# Borrowed from https://github.com/dom96/jester
# Very sligthly adjusted by me, 21DP4KLogi ~ 2025
# License (MIT/Expat):
#[
Copyright (C) 2015 Dominik Picheta

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
]#

import std/[tables, times, parseutils]

type
  SameSite* = enum
    None, Lax, Strict

proc makeCookie*(key, value, expires: string, domain = "", path = "",
                 secure = false, httpOnly = false,
                 sameSite = Lax): string =
  result = ""
  result.add key & "=" & value
  if domain != "": result.add("; Domain=" & domain)
  if path != "": result.add("; Path=" & path)
  if expires != "": result.add("; Expires=" & expires)
  if secure: result.add("; Secure")
  if httpOnly: result.add("; HttpOnly")
  result.add("; SameSite=" & $sameSite)

#[
  Slightly modified from original, combines these 2 pieces of code from the original:

  proc daysForward*(days: int): DateTime =
    ## Returns a DateTime object referring to the current time plus ``days``.
    return getTime().utc + initTimeInterval(days = days)

  format(expires.utc, "ddd',' dd MMM yyyy HH:mm:ss 'GMT'"),
]#
proc daysForward*(days: int): string =
  let expirationTime = getTime().utc + initTimeInterval(days = days)
  return format(expirationTime.utc, "ddd',' dd MMM yyyy HH:mm:ss 'GMT'")

proc parseCookies*(s: string): Table[string, string] =
  ## parses cookies into a string table.
  ##
  ## The proc is meant to parse the Cookie header set by a client, not the
  ## "Set-Cookie" header set by servers.

  result = initTable[string, string]()
  var i = 0
  while true:
    i += skipWhile(s, {' ', '\t'}, i)
    var keystart = i
    i += skipUntil(s, {'='}, i)
    var keyend = i-1
    if i >= len(s): break
    inc(i) # skip '='
    var valstart = i
    i += skipUntil(s, {';'}, i)
    result[substr(s, keystart, keyend)] = substr(s, valstart, i-1)
    if i >= len(s): break
    inc(i) # skip ';'
