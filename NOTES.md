# Notes

## Compiler JS interface (step 0)

Read at `grammo` commit `313013f` ("JS frontend dummy"). Toolchain: OCaml 5.5.0,
dune 3.24.2, js_of_ocaml 6.5.0. This was found by reading the source; nothing
has been built or run yet. Items marked *(confirm in step 1/2)* are expectations.

### Exports

`bin/grammo_js.ml` calls `Js.export "dslc" object%js ... end`, so the only
exported name is `dslc`, with one method:

```ts
dslc.compile(src: string): { error: string | null, code: string | null }
```

`src` goes straight into `Js.to_string`, so it must be a real JS string.

`Js.export` writes to js_of_ocaml's `jsoo_exports` object. That should be
`module.exports` under CommonJS `require` and the global object otherwise, so
`self.dslc` after `importScripts` in a worker. *(confirm in step 2 and step 9)*

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

**Thrown, not returned.** Neither `compile_string` nor `grammo_js.ml` has a
catch-all, so these escape `dslc.compile` as JS exceptions:

| Source | Trigger |
|---|---|
| `Process.ml:27` `Invalid_argument` | Unknown block class, e.g. `foo(y)` |
| `Process.ml:35` `Invalid_argument` | Unknown argument name |
| `Process.ml:41` `Invalid_argument` | Too many positional arguments |
| `Process.ml:136` `Invalid_argument` | Grouping terms, e.g. `(1 + x1 \| group)` |
| `lexer.mll` `INT (int_of_string n)` `Failure` | Integer literal too large to fit |
| `Parse.ml` `assert false` on `Rejected` | Should be unreachable |

The value thrown is expected to be a js_of_ocaml-encoded OCaml exception rather
than a JS `Error`, so `.message` can't be relied on. *(confirm in step 2)*

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
- Output: `grammo/_build/default/bin/grammo_js.bc.js`. Not built yet.
- `dune-project` is `(lang dune 3.21)`. There is no `js_of_ocaml` flags stanza,
  so the profile's defaults apply.

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

1. **`code` holds an AST dump, not Stan.** This is the most significant one. The
   contract says `code: "<stan code>"`. The fix belongs in `lib/driver/JS.ml`,
   see item 4.
2. **Non-parse failures throw instead of returning `{ error }`.** See the table
   above. The contract only describes a returned object, so either the OCaml
   side needs a catch-all or `main.js`/the worker must catch and convert.
3. **The function is `dslc.compile`, not a bare `compile`.** Only affects the JS
   glue.
4. **Where a fix may go is unclear.** Plan step 3 and `Claude.md` only allow
   changing `bin/grammo_js.ml`, and the root `Claude.md` forbids modifying the
   compiler otherwise. Item 1 needs a change in `lib/driver/JS.ml`, and only the
   catch-all from item 2 could live in `bin/grammo_js.ml`.

Compatible but worth knowing:

- `code` and `error` are never both set today. The contract allows it, so the
  Elm decoder should still handle it.
- No warnings are produced, so `Compiled.warnings` will always be `[]`.
- The error message has no `pos`/`msg` separator, which is cosmetic.

### Environment and instructions

5. **Node and npm are not installed in the container**, while `Claude.md` says
   to use whichever LTS is there. Blocks step 2 onwards.
6. **File and directory names differ from the docs.** The docs say `CLAUDE.md`,
   `PLAN.md` and `web/`. The real names are `Claude.md`, `Plan.md` and
   `grammo-web/`. `Claude.md` also mentions `web/dist/`, assumed to mean
   `grammo-web/dist/`.
7. **Plan step 2 has a truncated sentence** ("taken from , and prints").
   Assumed to mean `Examples.md`.
