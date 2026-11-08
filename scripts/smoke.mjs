// Smoke test: load the built compiler in Node and compile the two programs
// from Examples.md. The first must succeed and the second must fail.
//
// Build the compiler first: in ../grammo, run
//   dune build --profile release bin/grammo_js.bc.js

import { readFileSync } from "node:fs";
import { createRequire } from "node:module";

// This file is an ES module, but js_of_ocaml's output is a classic script that
// attaches its exports to CommonJS `module.exports`. `require` is the way to
// load that, and ES modules have to create it themselves. Relative paths are
// resolved against this file, not the current directory.
const require = createRequire(import.meta.url);
const { grammoc } = require("../../grammo/_build/default/bin/grammo_js.bc.js");

const examples = readFileSync(new URL("../Examples.md", import.meta.url), "utf8");
const programs = [...examples.matchAll(/^```\n([\s\S]*?)^```/gm)].map((m) => m[1]);
if (programs.length !== 2) {
  throw new Error(`Expected 2 programs in Examples.md, found ${programs.length}`);
}

const status = (result) => (result.error === null ? "ok" : "error");

const [valid, invalid] = programs.map((source) => grammoc.compile(source));

console.log(
  JSON.stringify(
    [
      { program: programs[0], status: status(valid), result: valid },
      { program: programs[1], status: status(invalid), result: invalid },
    ],
    null,
    2,
  ),
);

// Setting exitCode rather than calling process.exit lets the output flush.
if (status(valid) !== "ok" || status(invalid) !== "error") {
  console.error("Smoke test failed: expected one ok and one error result.");
  process.exitCode = 1;
}
