import sprae from "sprae";

declare function hash(input: string): string;
declare function solve(hash: string, salt: string, maxInt: number);

// Currently for debugging, requires a --global-name parameter for ESBuild
export async function solveChallenge() {
  let responseData = (await processedFetch("/api/challenge")).split(":");
  let salt = responseData[0]
  let hash = responseData[1]
  let signature = responseData[2]
  let secretNumber = solve(hash, salt, 1000000);
  console.log(secretNumber)
  return salt + ":" + signature + ":" + secretNumber.toString();
}

async function processedFetch(endpoint: string): Promise<string> {
  return await (await fetch(endpoint)).text();
}

async function initPage(): Promise<void> {
  let content = await processedFetch("/api/init");
  let parsedContent = content.split(":");
  state.serverCount = parsedContent[0];
  state.motd = parsedContent[1];
}

async function register(): Promise<void> {
  state.registerOngoing = true
  let powSolution = await solveChallenge();
  let response = await fetch("/api/register", {
    method: "POST",
    body: powSolution
  })
  switch (response.status) {
    case 400:
      alert("Error: Server considers request malformed (400 response)");
    case 401:
      alert("Error: Server considers solution incorrect (401 response)");
    case 200:
      state.registeredCode = await response.text();
  }
  state.registerOngoing = false
}

let scope = {
  serverCount: 0,
  pingServerCounter: async () => {state.serverCount = await processedFetch("/api/counter")},
  motd: "",
  registeredCode: "",
  registerOngoing: false,
  registerFunc: register,
  // getMotd: async () => {state.motd = await processedFetch("/api/motd")},
}

let state = sprae(document.body, scope);
initPage();
