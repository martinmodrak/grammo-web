# web/ — Elm frontend for Grammo
 
A static single-page app: the user edits Grammo DSL code in the left pane, presses
**Compile** (or Ctrl/Cmd+Enter), and the compiled Stan code and any potential errors
or warnings
appears in the right pane. Everything runs in the browser; there is no server.
 
## About the user
 
The user is fluent in Elm and OCaml but wants to **understand every piece of the
JS tooling and glue**. So:
 
- Keep things small and plain. Prefer fewer dependencies and less magic.
- At the end of every step, explain briefly what you added and *why*,
  especially for JS/Vite/npm/browser parts. Point out anything non-obvious.
- If there are several reasonable ways to do something, say so in one or two lines
  and go with the simplest, unless the plan says otherwise.
## Architecture
 
```
OCaml compiler ──js_of_ocaml──▶ public/grammo.js (generated, not committed)
                                     ▲ importScripts
                               public/compiler-worker.js  (classic Web Worker)
                                     ▲ postMessage
                                 src/main.js  (JS glue: ports ↔ worker)
                                     ▲ ports
                                 src/Main.elm (all app logic and UI)
                                     │ Html.node
                                 src/editor.js  (<code-editor> custom element wrapping CodeMirror 6)
```
 
- **Elm owns all state and UI.** JS is limited to: the port glue, the worker,
  and the custom elements. Keep JS files short and boring.
- **The compiler runs in a Web Worker** (after the step that introduces it).
  That keeps the UI responsive and lets us terminate a compile that runs too long.
- **The js_of_ocaml output is not an ES module.** It's loaded with
  `importScripts` in a classic worker served from `public/`, which Vite copies
  as-is. Don't try to bundle it.
## Compiler result format (contract between OCaml and Elm)
 
For the first proof of concept implementation,
`compile(source: string)` returns a plain JS object, in the shape:
 
```js
{ error: "<message>" (or null);    code: "<stan code>" (or null) }
```

It is possible that code is returned as well as an error (when grammo compilation succeeds, but the resulting Stan code is not valid). 
 
The Elm side decodes this into:
 
```elm
type CompileResult
    = Compiled { code : String, warnings : List Diagnostic }
    | Failed (List Diagnostic)
```

When for the first step there is always a single diagnostic (taken from `error` in the `compile` output) and the diagnostic is just string (later we will add code locations).
 
Don't change `bin/grammo_js.ml` 
yourself. If there are problems ask. 
 
## Tooling
 
- Elm 0.19.3, installed as an npm dev dependency (`elm`), plus `elm-format`
  and `elm-test`. All Elm code must be `elm-format`ted.
- Vite with `vite-plugin-elm`. Plain CSS in `src/style.css`. No CSS framework.
- CodeMirror 6 (`codemirror`, `@codemirror/*` packages) for the editors.
- **Ask before adding any npm or Elm dependency** that isn't listed here.
- Node: use whatever LTS is in the container; record the version in `NOTES.md`.
### Commands (keep `package.json` scripts matching this list)
 
```sh
npm install
npm run build:compiler   # dune release build of the JS target + copy to public/grammo.js
npm run dev              # Vite dev server
npm run build            # build:compiler + Vite production build into web/dist/
npm test                 # elm-test (+ the node smoke test once it exists)
npm run format           # elm-format --yes src/ tests/
```
 
The dev server runs inside a Docker container. Bind it to `0.0.0.0` (Vite
`server.host`) so the user can open it from the host. Use port 5173 unless told
otherwise.
 
## Conventions
 
- Elm modules: `Main.elm` to start; split out `Compiler.elm` (ports, types,
  decoders) once it grows. Avoid `Debug.log` in committed code.
- Decoders get elm-test tests with JSON samples taken from real compiler output.
- Custom elements: register them in JS *before* `Elm.Main.init`. Elm renders
  them with **no children**. Content goes in via `Html.Attributes.property`, and
  changes come out via custom DOM events decoded with `Html.Events.on`. The
  element only replaces its document when the incoming value really differs
  (otherwise the cursor jumps).
- `.gitignore` must cover: `node_modules/`, `dist/`, `elm-stuff/`,
  `public/grammo.js`.
- The site must work when served from a sub-path (GitHub Pages:
  `https://<user>.github.io/<repo>/`), so use relative URLs or Vite's `base`.
## Workflow for each step
 
1. Read `web/PLAN.md` and find the **first unchecked step**. Do only that step.
2. Before writing code, state in 2–4 lines what you're going to do. If the step
   is ambiguous, ask instead.
3. Implement it. Run the relevant commands (build, tests, format) and make sure
   they pass.
4. Tick the step in `PLAN.md` and add anything learned to `NOTES.md`.
5. Make a git commit (`web: step N — <title>`), but **do not push**.
6. Stop and report: what changed, why, how the user can try it, and anything
   that surprised you. Then wait.
