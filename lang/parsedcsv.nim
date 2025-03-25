import std/[strutils, tables]
# The std/parsecsv cannot be used at compile time, so made my own, more intuitive (i think) solution

proc tableize(file: string): Table[string, seq[string]] =
  let
    fileContent = readFile(file)
    lines = fileContent.splitLines
    headers = lines[0].split(",")
  var firstlineSkipped = false
  for header in headers:
    result[header] = newSeq[string](0)
  for line in lines:
    if not firstlineSkipped:
      firstlineSkipped = true
      continue
    let row = line.split(",")
    for index, element in pairs(row):
      if element == "": break
      result[headers[index]].add element

const namesCsv* = static(tableize("./lang/names.csv"))
