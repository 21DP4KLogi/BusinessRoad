import sprae from "sprae";
import {localise} from "./localisation.ts";
import langLengthsJson from "../dist/langdata.json"
import modelDataJson from "../dist/modeldata.json"

declare function solve(hash: string, salt: string, maxInt: number): number;

type numberStringPair = [number, string]

const defaultGameData = {
  money: -1,
  firstname: -1,
  lastname: -1,
  gender: "",
  businesses: [],
}
const modeldata = modelDataJson
const langLengths = langLengthsJson
let ws: WebSocket|null = null
let wsPingIntervalId = 0

function localise(lang: Object, key: string, parameters: Array<number> = []): string {
  let text: string|undefined = lang[key]
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

async function processedFetch(endpoint: string): Promise<string> {
  return await (await fetch(endpoint)).text();
}

async function solveChallenge(): Promise<string> {
  let responseData = (await processedFetch("/api/challenge")).split(":");
  let salt = responseData[0]
  let hash = responseData[1]
  let signature = responseData[2]
  let secretNumber = solve(hash, salt, 1000000);
  if (secretNumber == -1) {
    return "err";
  }
  // console.log(secretNumber)
  return salt + ":" + signature + ":" + secretNumber.toString();
}

function parseAndApplyGamedata(data: object|null): void {
  if (data === null) {
    state.gd = defaultGameData;
    return;
  }
  let parsedData = data;
  state["gd"] = parsedData
}

async function initPage(): Promise<void> {
  let response = await fetch("/api/init");
  if (response.status == 502) {
    alert("Error: API server is offline (502)");
    return;
  }
  let responseText = await response.text();
  let content = JSON.parse(responseText);
  state.authed = content["gameData"] != null;
  state.motd = content["motd"];
  state.lang = JSON.parse(content["lang"])
  document.documentElement.setAttribute("lang", "en")
  parseAndApplyGamedata(content["gameData"])
  if (state.authed) {
    openGamePage();
  }
  state.loaded = true;
}

async function register(): Promise<void> {
  state.authOngoing = true
  let powSolution = await solveChallenge();
  if (powSolution == "err") {
    alert("Error: The PoW solver returned -1");
    return;
  }
  let response = await fetch("/api/register", {
    method: "POST",
    body:
      powSolution + ":"
      + state.authPage.selGender + ":"
      + state.authPage.selFname + ":"
      + state.authPage.selLname
  })
  switch (response.status) {
    case 400:
      alert("Error: Server considers request malformed (400)");
    case 401:
      alert("Error: Server considers solution incorrect (401)");
    case 200:
      state.authPage.codeInput = await response.text();
  }
  state.authOngoing = false
}

async function login(): Promise<void> {
  state.authOngoing = true
  let powSolution = await solveChallenge();
  if (powSolution == "err") {
    alert("Error: The PoW solver returned -1");
    state.authOngoing = false
    return;
  }
  let code = state.authPage.codeInput;
  let response = await fetch("/api/login", {
    method: "POST",
    body: code + ":" + powSolution
  })
  switch (response.status) {
    case 400:
      alert("Error: Server considers request malformed (400)");
      break;
    case 401:
      alert("Error: Server considers solution incorrect (401)");
      break;
    case 404:
      alert("Error: Server cannot find user with that code (404)");
      break;
    case 200:
      let responseText = await response.text();
      let content = JSON.parse(responseText);
      parseAndApplyGamedata(content)
      state.authed = true;
      state.authPage.codeInput = "";
      break;
    default:
      alert("Error: Unexpected status code - " + response.status);
      break;
  }
  state.authOngoing = false
  if (state.authed) {
    openGamePage();
  }
}

async function deleteAccount(): Promise<void> {
  state.authOngoing = true
  let powSolution = await solveChallenge();
  if (powSolution == "err") {
    alert("Error: The PoW solver returned -1");
    state.authOngoing = false
    return;
  }
  let code = state.authPage.codeInput;
  let response = await fetch("/api/delete", {
    method: "POST",
    body: code + ":" + powSolution
  })
  switch (response.status) {
    case 400:
      alert("Error: Server considers request malformed (400)");
      break;
    case 401:
      alert("Error: Server considers solution incorrect (401)");
      break;
    case 404:
      alert("Error: Server cannot find user with that code (404)");
      break;
    case 204:
      alert("Account deleted successfully!")
      break;
    default:
      alert("Error: Unexpected status code - " + response.status);
      break;
  }
  state.authOngoing = false
}

async function logout(): Promise<void> {
  await fetch("/api/logout", {"method": "POST"});
  state.authed = false;
  state.curPage = "guest";
  state.fullName = "";
  state.money = -1;
  clearInterval(wsPingIntervalId)
  ws.close();
  ws = null;
}

async function changeLang(langCode: string): Promise<void> {
  let response = await processedFetch("/api/setlang/" + langCode);
  state.lang = JSON.parse(response);
  document.documentElement.setAttribute("lang", langCode)
}

async function openGamePage(): Promise<void> {
  ws = new WebSocket("/api/ws");
  ws.onopen = () => {
    // if (ws == null) return
    ws.addEventListener("message", (event) => wsHandler(event));
    ws.send("i")
    wsPingIntervalId = setInterval(function () {ws.send("i")}, 30000); 
  }
  state.curPage = "game"
}

function namelist(gender: "M"|"F", namepart: "firstname"|"lastname"): Array<numberStringPair> {
  let result: Array<numberStringPair> = []
  let length: number = langLengths[gender][namepart]
  for (let i = 0; i < length; i++) {
    result.push([i, state.l(namepart, [gender, i])]);
  }
  return result.sort( // Sorted alphabetically
    (a, b) => {return a[1].localeCompare(b[1])}
  );
}

// function foundBusiness(businessId: number): void {
//   ws.send("fb@" + businessId)
// }

function sendWsCommand(command: string, params: Array<string>): void {
  if (ws === null) return
  if (params.length < 1) {
    ws.send(command)
  } else if (params.length == 1) {
    ws.send(command + '@' + params[0])
  } else {
    let serializedParams = params[0]
    for (let i = 1; i < params.length; i++) {
      serializedParams += ":" + params[i]
    }
    ws.send(command + '@' + serializedParams)
  }
}

let scope = {
  lang: {},
  l(query: string, params: Array<number>) {return localise(this.lang, query, params)},
  loaded: false,
  motd: "",
  authed: false,
  wssend: sendWsCommand,
  curPage: "guest",
  authPage: {
    selGender: "M",
    selFname: 0,
    selLname: 0,
    action: "login",
    codeInput: "",
    namelist(namepart: "firstname"|"lastname") {return namelist(this.selGender, namepart)},
    buttonAction: () => {state.loginFunc()},
  },
  gamePage: {
    businessFields: modeldata["BusinessField"],
    businessProjects: modeldata["BusinessProject"],
    employeeProficiencies: modeldata["EmployeeProficiency"],
    businessInfoPane: {
      action: "",
      title: "",
      selectedExistingBusiness: -1,
      selectedNewBusiness: -1,
    },
  },
  authOngoing: false,
  registerFunc: register,
  loginFunc: login,
  deleteFunc: deleteAccount,
  logoutFunc: logout,
  changelangFunc: (langCode: string) => {changeLang(langCode)},
  gd: defaultGameData,
}

function wsHandler(event: MessageEvent) {
  let message = event.data;
  if (message === 'o') return
  console.log(message);
  let splitMessage = message.split('=');
  let command = splitMessage[0]
  let data = splitMessage?.[1] ?? ""
  switch (command) {
    case "m":
      state.gd.money = data;
      break;
    case "newbusiness":
      let parsedData = JSON.parse(data)
      state.gd.businesses.push({
        field: parsedData["field"],
        id: parsedData["id"]
      });
      break;
    default:
      alert("Server sent some incoherent gobbledegook via websocket")
  }
}

let state = sprae(document.body, scope);
initPage();
