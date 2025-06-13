import sprae from "sprae";
import { localise } from "./localisation.ts";
import langLengthsJson from "../dist/langdata.json";
import modelDataJson from "../dist/modeldata.json";
import colorThemesJson from "./colorThemes.json";
import { solve } from "../dist/public/pow.js";

enum BizItemCategory {
  None = 'N',
  Interviewee = 'I',
  Employee = 'E',
  Project = 'P',
}

type BizItemOptionSelection = [BizItemCategory, number];
type numberStringPair = [number, string];

type FrontendEmployee = {
  id: number;
  salary: number;
  proficiency: string;
  gender: "M" | "F";
  firstname: number;
  lastname: number;
};

type FrontendBusiness = {
  id: number;
  field: string;
  employees: Object;
  interviewees: Object;
  projects: Object;
};

type FrontendProject = {
  id: number;
  business: number;
  project: string;
  quality: number;
  active: boolean;
};

type GameData = {
  money: number;
  firstname: number;
  lastname: number;
  gender: "M" | "F";
  businesses: Object;
};

const defaultGameData: GameData = {
  money: -1,
  firstname: -1,
  lastname: -1,
  gender: "M",
  businesses: [],
};
const modeldata = modelDataJson;
const langLengths = langLengthsJson;
let ws: WebSocket | null = null;
let wsPingIntervalId = 0;

function localise(
  lang: Object,
  key: string,
  parameters: Array<number> = [],
): string {
  let text: string | undefined = lang[key];
  if (text === undefined) {
    return "";
  }
  let gaps: Array<string> | null = text.match(/\[.*?\]/g); // [Matches] [anything] [in] [square brackets]
  if (gaps == null) {
    return text;
  }
  for (let gap of gaps) {
    let trimmedGap = gap.slice(1, -1);
    let gapFill = lang["_"];
    for (let section of trimmedGap.split(".")) {
      let index =
        section.slice(0, 1) == "$" ? parameters[section.slice(1)] : section;
      // if (gapFill === undefined) {return ""}
      gapFill = gapFill[index];
    }
    text = text.replace(gap, gapFill);
  }
  return text;
}

async function processedFetch(endpoint: string): Promise<string> {
  return await (await fetch(endpoint)).text();
}

async function solveChallenge(): Promise<string> {
  let responseData = (await processedFetch("/api/challenge")).split(":");
  let salt = responseData[0];
  let hash = responseData[1];
  let signature = responseData[2];
  let secretNumber = solve(hash, salt, 1000000);
  if (secretNumber == -1) {
    return "err";
  }
  console.log(secretNumber)
  return salt + ":" + signature + ":" + secretNumber.toString();
}

function parseAndApplyGamedata(data: GameData | null): void {
  if (data === null) {
    state.gd = defaultGameData;
    return;
  }
  let parsedData = data;
  state["gd"] = parsedData;
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
  state.lang = JSON.parse(content["lang"]);
  document.documentElement.setAttribute("lang", "en");
  parseAndApplyGamedata(content["gameData"]);
  if (state.authed) {
    openGamePage();
  }
  state.loaded = true;
}

async function register(): Promise<void> {
  state.authOngoing = true;
  let powSolution = await solveChallenge();
  if (powSolution == "err") {
    alert("Error: The PoW solver returned -1");
    return;
  }
  let response = await fetch("/api/register", {
    method: "POST",
    body:
      powSolution +
      ":" +
      state.authPage.selGender +
      ":" +
      state.authPage.selFname +
      ":" +
      state.authPage.selLname,
  });
  switch (response.status) {
    case 400:
      alert("Error: Server considers request malformed (400)");
    case 401:
      alert("Error: Server considers solution incorrect (401)");
    case 200:
      state.authPage.codeInput = await response.text();
  }
  state.authOngoing = false;
}

async function login(): Promise<void> {
  state.authOngoing = true;
  let powSolution = await solveChallenge();
  if (powSolution == "err") {
    alert("Error: The PoW solver returned -1");
    state.authOngoing = false;
    return;
  }
  let code = state.authPage.codeInput;
  let response = await fetch("/api/login", {
    method: "POST",
    body: code + ":" + powSolution,
  });
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
      parseAndApplyGamedata(content);
      state.authed = true;
      openGamePage();
      state.authPage.codeInput = "";
      break;
    default:
      alert("Error: Unexpected status code - " + response.status);
      break;
  }
  state.authOngoing = false;
}

async function deleteAccount(): Promise<void> {
  state.authOngoing = true;
  let powSolution = await solveChallenge();
  if (powSolution == "err") {
    alert("Error: The PoW solver returned -1");
    state.authOngoing = false;
    return;
  }
  let code = state.authPage.codeInput;
  let response = await fetch("/api/delete", {
    method: "POST",
    body: code + ":" + powSolution,
  });
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
      alert("Account deleted successfully!");
      break;
    default:
      alert("Error: Unexpected status code - " + response.status);
      break;
  }
  state.authOngoing = false;
}

async function logout(): Promise<void> {
  await fetch("/api/logout", { method: "POST" });
  ws.close();
  ws = null;
  state.authed = false;
  state.curPage = "guest";
  // state.fullName = "";
  // state.money = -1;
  state.gamePage.businessInfoPane.action = "";
  state.gamePage.selBusinessIndex = -1;
  state.gamePage.unselectBizItem();
  state.gd = defaultGameData;
  clearInterval(wsPingIntervalId);
}

async function changeLang(langCode: string): Promise<void> {
  let response = await processedFetch("/api/setlang/" + langCode);
  state.lang = JSON.parse(response);
  document.documentElement.setAttribute("lang", langCode);
}

function setColorsToTheme(themeName: string): void {
  for (const [k, v] of Object.entries(colorThemesJson[themeName])) {
    document.documentElement.style.setProperty(k, v)
  }
}

function openGamePage(): void {
  ws = new WebSocket("/api/ws");
  ws.onopen = () => {
    // if (ws == null) return
    ws.addEventListener("message", (event) => wsHandler(event));
    ws.send("i");
    wsPingIntervalId = setInterval(function () {
      ws.send("i");
    }, 30000);
  };
  state.curPage = "game";
}

function namelist(
  gender: "M" | "F",
  namepart: "firstname" | "lastname",
): Array<numberStringPair> {
  let result: Array<numberStringPair> = [];
  let length: number = langLengths[gender][namepart];
  for (let i = 0; i < length; i++) {
    result.push([i, state.l(namepart, [gender, i])]);
  }
  return result.sort(
    // Sorted alphabetically
    (a, b) => {
      return a[1].localeCompare(b[1]);
    },
  );
}

// function foundBusiness(businessId: number): void {
//   ws.send("fb@" + businessId)
// }

function sendWsCommand(command: string, params: Array<string>): void {
  if (ws === null) return;
  if (params.length < 1) {
    ws.send(command);
  } else if (params.length == 1) {
    ws.send(command + "@" + params[0]);
  } else {
    let serializedParams = params[0];
    for (let i = 1; i < params.length; i++) {
      serializedParams += ":" + params[i];
    }
    ws.send(command + "@" + serializedParams);
  }
}

function dumpState() {
  console.log(state);
}

let scope = {
  debug: dumpState,
  lang: {},
  l(query: string, params: Array<number>) {
    return localise(this.lang, query, params);
  },
  // This causes an unnecessary lang object request
  get langcode() {return this.lang["langcode"]},
  set langcode(val) {if (!this.langcode) {return}; changeLang(val)},
  colortheme: "light",
  setColorsToTheme: setColorsToTheme,
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
    namelist(namepart: "firstname" | "lastname") {
      return namelist(this.selGender, namepart);
    },
    buttonAction: () => {
      state.loginFunc();
    },
  },
  gamePage: {
    selBusinessIndex: -1,
    businessInfoPane: {
      action: "",
      // title: "",
      newBusinessType: -1,
    },
    newProjectType: -1,
    suggestedSalary: -1,
    openNewBizMenu() {
      this.businessInfoPane.action = "new";
      this.businessInfoPane.newBusinessType = -1;
      this.selBusinessIndex = -1;
      this.unselectBizItem();
    },
    selBizItem: {
      action: BizItemCategory.None,
      id: -1
    },
    get selInterviewee() {return},
    set selInterviewee(val) {
      this.selBizItem = {action: BizItemCategory.Interviewee, id: val}
    },
    get selEmployee() {return},
    set selEmployee(val) {
      this.selBizItem = {action: BizItemCategory.Employee, id: val}
    },
    get selProject() {return},
    set selProject(val) {
      this.selBizItem = {action: BizItemCategory.Project, id: val}
    },
    unselectBizItem() {
      this.selBizItem = {action: BizItemCategory.None, id: -1}
    },
  },
  authOngoing: false,
  registerFunc: register,
  loginFunc: login,
  deleteFunc: deleteAccount,
  logoutFunc: logout,
  // This would make more sense next to `selBusinessIndex`, but I can't access `gd` from that scope
  get selBusiness() {
    if (this.gamePage.selBusinessIndex == -1) {return {}}
    return this.gd.businesses[this.gamePage.selBusinessIndex];
  },
  get selInterviewee() {
    return this.gd.businesses[this.gamePage.selBusinessIndex]?.interviewees[this.gamePage.selBizItem.id];
  },
  get selEmployee() {
    return this.gd.businesses[this.gamePage.selBusinessIndex]?.employees[this.gamePage.selBizItem.id];
  },
  get selProject() {
    return this.gd.businesses[this.gamePage.selBusinessIndex]?.projects[this.gamePage.selBizItem.id];
  },
  get selBizAvailableProjects() {
    // Buggy without deep copying
    return modeldata.AvailableProjects[this.selBusiness?.field]?.map(e => e) ?? [];
  },
  gd: defaultGameData,
  get data() {return modeldata}
};

function wsHandler(event: MessageEvent) {
  let message: string = event.data;
  if (message === "o") return;
  console.log(message);
  let splitMessage = message.split("=");
  let command = splitMessage[0];
  let data = splitMessage?.[1] ?? "";
  if (command === "ERR") {
    alert("Received error from WebSocket: " + data);
    return;
  }
  switch (command) {
    case "m": {
      state.gd.money = data;
      break;
    }
    case "newbusiness": {
      let parsedData = JSON.parse(data);
      state.gd.businesses[parsedData.id] = parsedData;
      state.gamePage.selBusinessIndex = parsedData.id;
      state.gamePage.businessInfoPane.action = "info";
      break;
    }
    case "interviewees": {
      let parsedData = JSON.parse(data);
      state.gd.businesses[parsedData["business"]].interviewees = {}
      if (state.gamePage.selBizItem.action == BizItemCategory.Interviewee) {
        state.gamePage.unselectBizItem();
      }
      for (let ntrvw of parsedData.interviewees) {
        state.gd.businesses[parsedData["business"]].interviewees[ntrvw.id] = ntrvw;
      }
      break;
    }
    case "newemployee": {
      let splitData = data.split(":");
      let businessId = splitData[0];
      let employeeId = splitData[1];
      let business: FrontendBusiness =
        state.gd.businesses[
          businessId
        ];
      if (state.selInterviewee?.id === Number(employeeId)) {
        state.gamePage.unselectBizItem()
      }
      business.employees[employeeId] = business.interviewees[employeeId];
      delete business.interviewees[employeeId];
      break;
    }
    case "loseemployee": {
      let splitData = data.split(":");
      let businessId = splitData[0];
      let employeeId = splitData[1];
      let business: FrontendBusiness =
        state.gd.businesses[
          businessId
        ];
      if (state.selEmployee?.id === Number(employeeId)) {
        state.gamePage.unselectBizItem();
      }
      delete business.employees[employeeId];
      break;
    }
    case "loseinterviewee": {
      let splitData = data.split(":");
      let businessId = splitData[0];
      let intervieweeId = splitData[1];
      let business: FrontendBusiness =
        state.gd.businesses[
          businessId
        ];
      if (state.selInterviewee?.id === Number(intervieweeId)) {
        state.gamePage.unselectBizItem();
      }
      delete business.interviewees[intervieweeId];
      break;
    }
    case "updateinterviewee": {
      let splitData = data.split(":");
      let businessId = splitData[0];
      let intervieweeId = splitData[1];
      let newSalary = Number(splitData[2]);
      let business: FrontendBusiness =
        state.gd.businesses[
          businessId
        ];
      business.interviewees[intervieweeId].salary = newSalary;
      break;
    }
    case "newproject": {
      let parsedData = JSON.parse(data);
      state.gd.businesses[parsedData.business].projects[parsedData.id] = {
        id: parsedData.id,
        business: parsedData.business,
        project: parsedData.project,
        quality: parsedData.quality,
        active: parsedData.active,
      };
      break;
    }
    case "wprojquality": {
      let parsedData = data.split(":");
      state.gd.businesses[parsedData[0]].projects[parsedData[1]].quality = parsedData[2];
      break;
    }
    case "dproj": {
      let parsedData = data.split(":");
      delete state.gd.businesses[parsedData[0]].projects[parsedData[1]];
      if (state.selProject?.id === Number(parsedData[1])) {
        state.gamePage.unselectBizItem();
      }
      break;
    }
    case "wprojactive": {
      let parsedData = data.split(":");
      state.gd.businesses[parsedData[0]].projects[parsedData[1]].active = parsedData[2] == "T";
      break;
    }
    default:
      alert("Server sent some incoherent gobbledegook via websocket");
  }
}

let state = sprae(document.body, scope);
initPage();
