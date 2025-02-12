import sprae from "sprae";

declare function hash(input: string): string;
declare function solve(hash: string, salt: string, maxInt: number);

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
