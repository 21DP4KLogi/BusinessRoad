export function localise(lang: Object, query: string): string {
  let text = lang[query]
  let gaps: Array<string> | null = text.match(/\[.*?\]/g) // [Matches] [anything] [in] [square brackets]
  if (gaps == null) {return text} 
  console.log(gaps)
  for (let gap of gaps) {
    text = text.replace(gap, lang[gap.slice(1,-1)])
  }
  return text;
}

export const en = {
  title: "Business Road",
  conjugationTest: "You are [firstname] [lastname], hi [firstname] [lastname]!",
  firstname: "Billy",
  lastname: "Nair",
}

export const lv = {
  title: "Biznesa Ceļš",
  conjugationTest: "Jūs esat [firstnameNom] [lastnameNom], sveiki [firstnameVoc] [lastnameVoc]!",
  firstnameNom: "Bilijs",
  lastnameNom: "Nērs",
  firstnameVoc: "Bilij",
  lastnameVoc: "Nēr",
}
