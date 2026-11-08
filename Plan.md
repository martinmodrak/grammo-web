# Frontend plan

Do **one step per turn**, top to bottom. Each step should be a small, reviewable
commit. "Done when" is the acceptance check. Run it before ticking the box.
The user may reorder, split, or drop steps. Follow this file as it currently is.

## Phase A — understand the compiler's JS interface (no frontend yet)

- [x] **0. Inspect.** Read `../grammo/bin/grammo_js.ml`, its `dune` stanza, and
  `dune-project`. Write `NOTES.md` containing: the exported name(s) and
  function signature(s), the exact shape of the returned object(s), how errors
  and exceptions are reported, the line/column base, the dune target that
  produces the JS file, and any example DSL programs found in the repo.
  *No code changes.* Done when: `NOTES.md` exists and you've listed every
  mismatch with the contract in `CLAUDE.md`.
- [x] **1. Build the JS.** Build the JS target in release mode. Record the
  exact command and output path in `NOTES.md`.
  Done when: the file builds from a clean `_build`.
- [x] **2. Node smoke test.** Add `scripts/smoke.mjs`. It loads the built
  file in Node, compiles one valid and one invalid example program (taken from , and prints
  both results as JSON. Done when: `node scripts/smoke.mjs` shows one `ok`
  and one `error` result.
- [x] **3. Align the result format (only if step 0 found mismatches).**
  Propose the exact change to `bin/grammo_js.ml` and **wait for approval**
  before editing OCaml. Done when: the smoke test output matches the contract.

## Phase B — Elm app with plain textareas

- [x] **4. Scaffold.** `package.json`, Vite + `vite-plugin-elm`, `elm.json`,
  `index.html`, `src/main.js`, and `src/Main.elm` showing "Hello Grammo".
  Add `.gitignore` and the npm scripts from `CLAUDE.md` (stubs are OK for
  ones not needed yet). Done when: `npm run dev` serves the page and
  `npm run build` produces `dist/`.
- [x] **5. Layout with a fake compiler.** Two side-by-side panes: a `<textarea>`
  for the DSL and a read-only `<pre>` for output, and another read-only `<pre>` for errors, plus a Compile button. The
  "compiler" is a pure Elm function (for example, upper-cases the input). No JS
  involved. Done when: typing then clicking Compile updates the right pane.
- [x] **6. Ports with a JS stub.** Add `port compile` / `port compiled`.
  `main.js` answers with a hard-coded JS stub that returns a contract-shaped
  object. Elm just shows the raw JSON for now. Done when: the round trip works
  in the browser.
- [x] **7. Decoder + error display.** Add the `CompileResult` type and decoder,
  and show Stan code and error. Add elm-test
  tests for the decoder, covering ok, error, warnings, and a malformed payload.
  Done when: `npm test` passes and both cases render with the stub.
- [x] **8. Real compiler on the main thread.** Implement `npm run build:compiler`
  (dune build + copy to `public/grammo.js`). Load it with a `<script>` tag and
  call it from `main.js`. Done when: real grammo code compiles in the browser.
- [ ] **9. Move it into a Web Worker.** `public/compiler-worker.js` uses
  `importScripts("grammo.js")`. `main.js` relays messages, tags each request
  with an id, and ignores stale responses. Done when: behaviour matches step 8
  and the main thread no longer loads `grammo.js`.
- [ ] **10. Timeout and robustness.** If a compile takes longer than N seconds
  (N in a constant), terminate and restart the worker and send Elm a
  "compiler timed out" result. Also handle worker load errors. Show a
  "compiling…" state in Elm. Done when: you can demonstrate the timeout, e.g.
  with a temporary stub that loops forever, which is then removed.

## Phase C — real editors

- [ ] **11. `<code-editor>` custom element, input pane.** Wrap CodeMirror 6 with
  a plain setup and no language mode. Replace the textarea. Done when: editing
  works, the cursor never jumps, and Elm state stays in sync.
- [ ] **12. Read-only output pane.** Reuse the element with a `readonly`
  property. Done when: compiled Stan shows in CodeMirror, and it's selectable
  and copyable.
- [ ] **13. Keyboard shortcut.** Ctrl/Cmd+Enter compiles. Done when: it works
  in the editor and outside it.

(step 14 intentionally skipped and remomved)

## Phase D — nice to have (confirm with user before starting each)

- [ ] **15. Grammo syntax highlighting.** Use a `StreamLanguage` mode based on
  the lexer in the OCaml sources.
- [ ] **16. Stan syntax highlighting.** Check whether a maintained CodeMirror 6
  Stan mode exists (and ask before adding it); otherwise write a small
  `StreamLanguage` mode.
- [ ] **17. Example picker.** Use a dropdown of example programs (the source
  for these is in `Examples.md`).
- [ ] **18. Shareable URL.** Put the source, compressed with `lz-string`, in the
  URL hash and restore it on load.

(step 20 skipped and removed)

## Phase E — deployment

- [ ] **20. Production build check.** Set the `base` path, run `npm run build`,
  and serve `dist/` with a static server under a sub-path. Done when:
  everything works from the sub-path.
