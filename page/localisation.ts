export function localise(lang: Object, query: string): string {
  let text = lang[query]
  let gaps: Array<string> | null = text.match(/\[.*?\]/g) // [Matches] [anything] [in] [square brackets]
  if (gaps == null) {return text} 
  for (let gap of gaps) {
    text = text.replace(gap, lang[gap.slice(1,-1)])
  }
  return text;
}

export const en = {
  title: "Business Road",
  greeting: "Hello, [firstname] [lastname]!",
  firstname: "Billy",
  lastname: "Nair",
  fullname: "[firstname] [lastname]",
  logout: "Log out",
  register: "Register",
  login: "Log in",
  delete: "Delete",
  moneyIndicator: "Money: $",
}

export const lv = {
  title: "Biznesa Ceļš",
  firstnameNom: "Bilijs",
  lastnameNom: "Nērs",
  fullname: "[firstnameNom] [lastnameNom]",
  greeting: "Sveiki, [firstnameVoc] [lastnameVoc]!",
  firstnameVoc: "Bilij",
  lastnameVoc: "Nēr",
  logout: "Izrakstīties",
  register: "Reģistrēties",
  login: "Pierakstīties",
  delete: "Dzēst",
  moneyIndicator: "Nauda: $",
}
