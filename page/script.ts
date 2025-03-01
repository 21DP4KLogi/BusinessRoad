import sprae from "sprae";

declare function hash(input: string): string;
declare function solve(hash: string, salt: string, maxInt: number): number;

async function solveChallenge(): Promise<string> {
  let responseData = (await processedFetch("/api/challenge")).split(":");
  let salt = responseData[0]
  let hash = responseData[1]
  let signature = responseData[2]
  let secretNumber = solve(hash, salt, 1000000);
  if (secretNumber == -1) {
    return "err";
  }
  console.log(secretNumber)
  return salt + ":" + signature + ":" + secretNumber.toString();
}

async function processedFetch(endpoint: string): Promise<string> {
  return await (await fetch(endpoint)).text();
}

async function initPage(): Promise<void> {
  let response = await fetch("/api/init");
  if (response.status == 502) {
    alert("Error: API server is offline (502)");
    return;
  }
  let content = await response.text();
  let parsedContent = content.split(":");
  state.amAuthed = parsedContent[0] == "1";
  state.motd = parsedContent[1];
  if (state.amAuthed) {
    openGamePage();
  }
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
    body: powSolution
  })
  switch (response.status) {
    case 400:
      alert("Error: Server considers request malformed (400)");
    case 401:
      alert("Error: Server considers solution incorrect (401)");
    case 200:
      state.authInput = await response.text();
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
  let code = state.authInput;
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
      state.amAuthed = true;
      break;
    default:
      alert("Error: Unexpected status code - " + response.status);
      break;
  }
  state.authOngoing = false
  if (state.amAuthed) {
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
  let code = state.authInput;
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
  state.isAuthed = false;
  state.curPage = "guest";
  ws.close();
  ws = null;
}

async function openGamePage(): Promise<void> {
  ws = new WebSocket("/api/ws");
  ws.onopen = () => {
    // if (ws == null) return
    ws.send("m?")
  }
  state.curPage = "game"
}

let scope = {
  motd: "",
  amAuthed: false,
  curPage: "guest",
  authInput: "",
  authOngoing: false,
  registerFunc: register,
  loginFunc: login,
  deleteFunc: deleteAccount,
  logoutFunc: logout,
  money: -1,
}
let ws: WebSocket|null = null

let state = sprae(document.body, scope);
initPage();
