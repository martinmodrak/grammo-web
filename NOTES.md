# Notes

## Node

Node v26.13.0 LTS ("Lithium"), linux-x64, from the official nodejs.org tarball
with its SHA-256 checked. It is unpacked in
`~/.local/lib/node-v26.13.0-linux-x64/`, with `node`, `npm` and `npx` symlinked
into `~/.local/bin`, which is already on `PATH`. This lives in the container's
home directory, so it has to be repeated if the container is rebuilt.

To remove it: delete that directory and the three symlinks.

## Compiler JS interface (step 0)

Read at `grammo` commit `313013f` ("JS frontend dummy"). Toolchain: OCaml 5.5.0,
dune 3.24.2, js_of_ocaml 6.5.0. Updated for `grammo` commit `aacdde0`. Items
marked *to confirm* are expectations that have not been run yet.

### Exports

`bin/grammo_js.ml` calls `Js.export "grammoc" object%js ... end`, so the only
exported name is `grammoc`, with one method:

```ts
grammoc.compile(src: string): { error: string | null, code: string | null }
```

`src` goes straight into `Js.to_string`, so it must be a real JS string.

`Js.export` writes to js_of_ocaml's `jsoo_exports` object. That should be
`module.exports` under CommonJS `require` and the global object otherwise, so
`self.grammoc` after `importScripts` in a worker. The `require` case is confirmed;
the worker case is still *(to confirm in step 9)*.

### Returned object

| Outcome | `error` | `code` |
|---|---|---|
| Success | `null` | string |
| Parse or lexer error | string | `null` |

Both are JS `null` when absent (`Js.null`), and both fields are always present.
The two are currently mutually exclusive. There is no warnings field.

**On success `code` is not Stan.** `lib/driver/JS.ml` returns
`Ast.show_program` of the processed AST, which is a debug dump. No Stan
generation is wired up for the JS path yet.

### Errors and exceptions

Returned as `{ error, code: null }`, from `Parse.program_of_string`:

- Syntax errors (Menhir `HandlingError`)
- `Lexer.Error` (unexpected character, identifier ending in `_`)
- `Surface.Error` (unknown type name)

The string is `"Parse error: " ^ pos ^ msg`, with `pos` as
`startLine:startCol-endLine:endCol`. There is **no separator between `pos` and
`msg`**, giving e.g. `Parse error: 1:0-1:3syntax error in state N\nSee
parser.messages...`. Syntax errors expose only a parser state number plus a
developer hint about regenerating `parser.messages`.

**Exceptions.** `compile_string` has no catch-all, so these raise. A catch-all
in `bin/grammo_js.ml` (commit `2652899`) turns them into
`{ error: "Compilation error: <Exn.to_string>", code: null }`, for example
`Compilation error: (Invalid_argument "Unknown argument names used")`:

| Source | Trigger |
|---|---|
| `Process.ml:27` `Invalid_argument` | Unknown block class, e.g. `foo(y)` |
| `Process.ml:35` `Invalid_argument` | Unknown argument name |
| `Process.ml:41` `Invalid_argument` | Too many positional arguments |
| `Process.ml:136` `Invalid_argument` | Grouping terms, e.g. `(1 + x1 \| group)` |
| `lexer.mll` `INT (int_of_string n)` `Failure` | Integer literal too large to fit |
| `Parse.ml` `assert false` on `Rejected` | Should be unreachable |

All of these except the unreachable `assert false` were run in Node against a
release build and came back as returned errors.

### Line and column base

From `Location.pos_from_lexing`:

- Lines are **1-based** (`pos_lnum`).
- Columns are **0-based** (`pos_cnum - pos_bol`).
- The end position is exclusive (`lexeme_end_p`).
- Columns count **UTF-8 bytes**, not characters. CodeMirror offsets are UTF-16,
  so non-ASCII text before an error on the same line will shift the column. This
  only matters once code locations are added.

Locations are only available embedded in the error string.

### Dune target

- Stanza: `(executable (name grammo_js) (modes js) ...)` in `bin/dune`, with
  `js_of_ocaml-ppx`, `grammo.driver` and `js_of_ocaml`.
- Target: `bin/grammo_js.bc.js`, confirmed with `dune rules`.
- Output: `grammo/_build/default/bin/grammo_js.bc.js`.
- `dune-project` is `(lang dune 3.21)`. There is no `js_of_ocaml` flags stanza,
  so the profile's defaults apply.

### Release build (step 1)

Run in `grammo/`, with the local opam switch active:

```sh
dune build --profile release bin/grammo_js.bc.js
```

Output: `grammo/_build/default/bin/grammo_js.bc.js`, about 1.9 MB. It was checked
from a clean state at `aacdde0` by adding `--build-dir=<empty dir>`, which leaves
the real `_build` alone.

### Example DSL programs

| Where | Program | Expected result |
|---|---|---|
| `Examples.md` | `data { df = {...} }` + `normal(y, sigma, mu = ~x1)` | Valid |
| `Examples.md` | `aaa` | Invalid |
| `grammo/lib/driver/CLI.ml:304` (`cli_parse`) | Same model plus `(1 + x1 \| group)` | Parses, then **throws** (grouping terms) |

`test/parsing` and `test/test_codegen.ml` are empty. The files in
`R_tests/customized_stan/` are Stan, not Grammo.

## Mismatches with `Claude.md`

### Compiler contract

1. **`code` holds an AST dump, not Stan.** Intentional placeholder, confirmed by
   the user. Treat it as valid output for now.
2. **Non-parse failures threw instead of returning `{ error }`.** Fixed by the
   catch-all in `bin/grammo_js.ml` (commit `2652899`).
3. **The function is `grammoc.compile`, not a bare `compile`.** Only affects the JS
   glue.

Compatible but worth knowing:

- `code` and `error` are never both set today. The contract allows it, so the
  Elm decoder should still handle it.
- No warnings are produced, so `Compiled.warnings` will always be `[]`.
- The error message has no `pos`/`msg` separator, which is cosmetic.

### Environment and instructions

4. **Node and npm were not installed in the container**, while `Claude.md` says
   to use whichever LTS is there. Resolved with a local install, see below.
5. **File and directory names differ from the docs.** The docs say `CLAUDE.md`,
   `PLAN.md` and `web/`. The real names are `Claude.md`, `Plan.md` and
   `grammo-web/`. `Claude.md` also mentions `web/dist/`, assumed to mean
   `grammo-web/dist/`.
6. **Plan step 2 has a truncated sentence** ("taken from , and prints").
   Assumed to mean `Examples.md`.

## Frontend tooling (step 4)

Versions are pinned exactly in `package.json`: vite 8.3.6, vite-plugin-elm 3.0.1,
elm 0.19.3-0, elm-format 0.8.8, elm-test 0.19.3-0.

- **`npm audit` reports 3 high-severity issues**, all from `cross-spawn` via
  `node-elm-compiler`, a dependency of vite-plugin-elm. It only runs at
  development time and is not bundled into the site.


## Elm decoder (step 7)

`Compiler.decoder` maps the compiler's result as follows:

| `error` | `code` | Result |
|---|---|---|
| `null` | string | `Compiled` with no warnings |
| string | `null` | `Failed [ error ]` |
| string | string | `Compiled` with `error` as its one warning |
| `null` | `null` | Decode failure |

`Compiler.fromValue` shows decode failures to the user as `Failed`. The tests
use neutral sample strings, because the decoder only depends on the JSON shape.

Keep `Main.elm` importing a local module: vite-plugin-elm 3.0.1 generates
`accept([""])` without one, and Vite then returns 500 for `Main.elm`.

## Real compiler (step 8)

`npm run build:compiler` runs the release build and copies the result to
`public/grammo.js`. Run it once before `npm run dev`, and again after changing
the compiler. `npm run build` runs it automatically.

- The copy uses `cp -f` because dune's output is read-only, so a plain `cp`
  would fail when overwriting an earlier copy.
- Vite copies everything in `public/` to `dist/` unchanged, and the compiler is
  never bundled.
- `scripts/smoke.mjs` was removed at the user's request, so `npm test` is only
  elm-test and no longer needs the compiler built.
