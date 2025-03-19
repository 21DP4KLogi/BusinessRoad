import std/[sugar]

# Returns a 'column' of a 1D array that has been structured like a table
# I did this so i could write the names in a more common tabular format
proc column*(arr: array, col: Positive, colCount: Positive): seq =
  collect(newSeq):
    for index in countup(col - 1, arr.len - 1, colCount):
      arr[index]
