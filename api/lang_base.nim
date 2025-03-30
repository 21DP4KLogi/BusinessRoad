import std/[tables]
import "../lang"/[data, en, lv]

export data

const DefaultLang* = "en"

# TODO: Come up with a solution to this mild mess:
# Since JsonNodes are not valid as constant values (idk why), I store them as strings.
# But since I store them as strings, putting them into a Json object causes all their quotes
# (of which there are a lot) to be escaped, adding to the file size, which... is likely not
# that significant, but it has no advantages other than Nim letting me do that.
const langs* = {
  "en": en.lang,
  "lv": lv.lang,
}.toTable
