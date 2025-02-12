import sprae from "sprae";

declare function hash(input: string): string;
declare function solve(hash: string, salt: string, maxInt: number);

// Currently for debugging, requires a --global-name parameter for ESBuild
export async function solveChallenge() {
  let responseData = (await processedFetch("/api/challenge")).split(":");
  let salt = responseData[0]
  let hash = responseData[1]
  let signature = responseData[2]
  let secretNumber = solve(hash, salt, 5);
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

let scope = {
  serverCount: 0,
  pingServerCounter: async () => {state.serverCount = await processedFetch("/api/counter")},
  motd: "",
  // getMotd: async () => {state.motd = await processedFetch("/api/motd")},
}

let state = sprae(document.body, scope);
initPage();
