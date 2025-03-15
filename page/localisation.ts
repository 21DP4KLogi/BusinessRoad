export function localise(lang: Object, key: string, parameters: Array<number> = []): string {
  let text = lang[key]
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

export const en = {
  title: "Business Road",
  greeting: "Hello, [firstname.$0] [lastname]!",
  fullname: "[firstname.$0] [lastname]",
  logout: "Log out",
  register: "Register",
  login: "Log in",
  delete: "Delete",
  moneyIndicator: "Money: $",
  _: {
    firstname: ["Billy", "Miller"],
    lastname: "Nair",
  }
}

export const lv = {
  title: "Biznesa Ceļš",
  fullname: "[firstnameNom.$0] [lastnameNom]",
  greeting: "Sveiki, [firstnameVoc.$0] [lastnameVoc]!",
  logout: "Izrakstīties",
  register: "Reģistrēties",
  login: "Pierakstīties",
  delete: "Dzēst",
  moneyIndicator: "Nauda: $",
  _: {
    firstnameNom: ["Bilijs", "Millers"],
    lastnameNom: "Nērs",
    firstnameVoc: ["Bilij", "Miller"],
    lastnameVoc: "Nēr",
  }
}
