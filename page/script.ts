import sprae from "sprae";

declare function hash(input: string): string;
declare function solve(hash: string, salt: string, maxInt: number);

let pingServerCounter = async () => {
  state.serverCount = await (await fetch("/api/counter")).text();
}

let scope = {
  serverCount: 0,
  pingServerCounter: pingServerCounter
}

let state = sprae(document.body, scope);

pingServerCounter()
