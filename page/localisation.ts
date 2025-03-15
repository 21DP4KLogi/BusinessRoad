export function localise(lang: Object, key: string, parameters: Array<number> = []): string {
  let text = lang[key]
  if (text === undefined) {return ""}
  let gaps: Array<string> | null = text.match(/\[.*?\]/g) // [Matches] [anything] [in] [square brackets]
  if (gaps == null) {return text} 
  for (let gap of gaps) {
    let trimmedGap = gap.slice(1,-1)
    let gapFill = lang["_"]
    for (let section of trimmedGap.split(".")) {
      let index = section.slice(0, 1) == "$" ? parameters[section.slice(1)] : section
      gapFill = gapFill[index]
    }
    text = text.replace(gap, gapFill)
  }
  return text;
}
