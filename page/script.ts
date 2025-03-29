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
}
const modeldata = modelDataJson
const langLengths = langLengthsJson
let ws: WebSocket|null = null
let wsPingIntervalId = 0


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


let scope = {
  lang: {},
  l(query: string, params: Array<number>) {return localise(this.lang, query, params)},
  loaded: false,
  motd: "",
  authed: false,
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
    get businessFields() {return modeldata["BusinessField"]},
    get businessProjects() {return modeldata["BusinessProject"]},
    get employeeProficiencies() {return modeldata["EmployeeProficiency"]},
    businessInfoPaneAction: "",
  },
  authOngoing: false,
  registerFunc: register,
  loginFunc: login,
  deleteFunc: deleteAccount,
  logoutFunc: logout,
  changelangFunc: (langCode: string) => {changeLang(langCode)},
  gd: defaultGameData,
}

let state = sprae(document.body, scope);
initPage();
