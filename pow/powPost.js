// let hash = Module.cwrap("hash", "string", ["string"])
/** @type {(hash: string, salt: string, maxInt: number) => number} */
export const solve = Module.cwrap("solve", "number", ["string", "string", "int"])
