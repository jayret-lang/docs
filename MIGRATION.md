# Migrating a Pyret-flavored docs repo to Jayret

This is the playbook used on `jayret-lang/docs` (this repo, Scribble/Racket
build). It captures phase ordering, the tools we wrote, and the gotchas
worth knowing before applying the same procedure to
[`jayret-lang/dcic`](https://github.com/jayret-lang/dcic) or any future
Pyret-derived doc set.

Commits worth re-reading alongside this doc:
`577765d` (translator + scope pruning + bulk translation),
`d529a23` (prose rebrand),
`dba87a5` (broken-xref fixes),
`a935ce0` (URL canonicalization),
`783365b` (`.arr` mop-up + screenshot triage + PARITY),
`e788694` (Pyret→Jayret test syntax in prose).

See also: [`PARITY.md`](PARITY.md) for the remaining gaps.

## Goal and shape

Take an upstream Pyret docs site and produce a Jayret-flavored equivalent:

- Code samples render Jayret syntax (braces, `@Check`, `switch`/`case`,
  type-before-name).
- Prose, titles, and URLs refer to Jayret, not Pyret.
- Features Pyret has and Jayret hasn't yet are *named and parked*, not
  silently dropped.
- The build stays clean and the site keeps deploying.

The diff should read as one coherent rebrand, not a thousand spot edits.

## Source/target infrastructure (read this first)

| | jayret-docs (this repo) | jayret-lang/dcic |
|---|---|---|
| Source format | Scribble (`.scrbl`, Racket) | Pandoc Markdown (`.md`) |
| Build | `racket run.rkt …` (see Makefile) | `python3 build.py --all` |
| Output | `build/docs/` | `docs/` (committed) |
| Deploy | CI workflow `.github/workflows/deploy-pages.yml` triggers on push to `horizon` | GitHub Pages serves `docs/` directly; no CI |
| Branch | `horizon` | `main` |
| Code-block macro | `@pyret-block{…}` | fenced ```` ```pyret ```` blocks |
| Inline-code macro | `@pyret{…}` | backtick `` `code` `` (no language tag) |
| Identifier xref macro | `@pyret-id["name" "module"]` | n/a (manual links) |
| Built-in HTML banner inject point | `src/myprefix.html` via Scribble's `--prefix` | `templates/dcic.html` (Pandoc template) |

The conceptual phases below are *infrastructure-agnostic*; the **tools we
wrote** (`tools/pyret2jayret.mjs`, `tools/prose-rebrand.py`) are
Scribble-aware and will need adaptation for DCIC's Markdown.

## Phases (in execution order)

### 0. Triage and inventory

Before touching anything:

- `git remote -v` — confirm the fork is yours and the upstream is the
  Pyret docs source.
- `git log --oneline -20` — what's already done on the branch.
- Count and locate the code-block macro sites:
  ```
  grep -rohE '@pyret[a-z-]*' src/ | sort | uniq -c | sort -rn
  ```
- Run the existing build and capture warnings as your **baseline**.
  Anything that warns before you start is "not yours to fix unless asked"
  — but record it so the post-migration build delta is auditable. The 8
  `report-undocumented` warnings on `filesystem` were ours-baseline; we
  noted them in PARITY rather than fixing.
- Take a baseline screenshot of `index.html` and one chapter via headless
  Chromium. Useful for visual-regression sanity later.

For DCIC: also check `conversion-status.md` and `HANDOFF.md` if they
exist. DCIC has a Markdown intermediate so the "source" is already
relatively clean.

### A. Build a code-block translator

The hand-rolled mini-parser approach (we tried it first) plateaus at ~66%
coverage on real files — `use context`, `provide from … end`, new-style
`include from M: data *` etc. blow up. **Reuse Pyret's actual parser**:

- Pyret's tokenizer + parser are AMD modules at:
  - `<pyret-lang>/src/js/base/pyret-tokenizer.js`
  - `<pyret-lang>/build/phaseA/js/pyret-parser.js`
  - depend on `<pyret-lang>/lib/jglr/{cyclicJSON,rnglr,jglr}.js`
- Load them via a minimal AMD `define()` shim in Node (see
  [[pyret-frontend-amd-shim]] memory or `tools/pyret2jayret.mjs`).
- The parser returns a **CST**, not the Pyret AST. Walk the CST keyed on
  `.name` (`program`, `block`, `stmt`, `fun-expr`, `cases-expr`, `if-expr`,
  `data-expr`, `check-expr`, `check-test`, etc.) and emit Jayret strings.
- **Pyret tokenizer drops comments.** Pre-extract `#…`/`#|…|#` regions
  with their start lines, replace each with same-width whitespace so
  token positions are preserved, parse, then re-splice comments at
  matching output line positions.
- One Pyret-grammar quirk worth knowing: bare unary `-` at expression
  start (e.g. `if c: -n else: n end`) fails to parse — the source needs
  parens (`(0 - n)` or `(-n)`). Surfaces as a "no shifts" parse failure.

What the translator should emit per Jayret spec:

- Function decl: `int square(int n) { return n * n; }` (return lifted
  from the tail expression in the body).
- `if`/`else if`/`else` → `if (...) { ... } else if (...) { ... } else { ... }`
- `cases(T) v: | empty => 0 | link(f, r) => f end`
  → `switch (v) { case Empty: yield 0; case Link(f, r): yield f; }`
  (variants in PascalCase.)
- `data Shape: | circle(r :: Number) end`
  → `data Shape { Circle(int r); }`
- `check "math": x is y end`
  → `@Check void math() { assertEquals(x, y); }` (named) or
  `@Check { ... }` (anonymous; see "Test-syntax caveats" below).
- `for each(x from xs): ... end` → `for (x : xs) { ... }`
- `for map(x from xs): ... end` → `[for map(x : xs) { yield ...; }]`
- `lam(n): n * 2 end` → `(n) -> n * 2`

**The macro-name rename decision.** The natural follow-on is to rename
`@pyret-block` → `@jayret-block`, `@pyret` → `@jayret`, etc. We
**deferred this** because it adds ~750 mechanical edits with no rendering
change. The translator's `rewriteScribble` has the rename behind a
flag; the aliases in `scribble-api.rkt` are reverted. To finish later:
re-add the aliases, flip the rename on, re-run.

**Escape `@` in translated bodies.** Scribble's at-reader interprets
`@FOO` inside a macro body as a call to `FOO`. Jayret's `@Check`
annotation collides. The translator rewrites `@` → `@"@"` in everything
it emits into a Scribble code-block body. For DCIC's Markdown there is no
at-reader; this escape isn't needed.

Validate:
```
node tools/pyret2jayret.mjs --self-test          # built-in unit tests
node tools/pyret2jayret.mjs --dry-run src/lang/*.scrbl   # coverage report
```
Aim for ≥90% pass. The ~10% that don't translate are mostly intentional
`bad-ex` snippets, `<meta-placeholders>`, and new-style provide/include
forms (`data *`, `module *`, `hiding`) that the phaseA parser doesn't
accept. The translator tags them with `@; TODO(pyret2jayret): …`.

### B. Scope pruning

Some upstream sections are off-topic for the Jayret edition:

- Pyret-Tutorial (the Lander game)
- Internals (compiler/runtime FFI internals — Jayret reuses Pyret's
  runtime unchanged)
- libraries-archived (upstream-deprecated)
- The reactors documentation (no Jayret surface syntax yet)

Move these into `src/_archive/` so they can be revived but don't ship.
Update `src/index.scrbl` and `src/libraries.scrbl` includes accordingly.
If an archived file held a Racket helper that a kept file still requires
(we hit this with `math-utilities.rkt`), relocate the helper, don't lose
it (`src/utils/`).

Decide per-feature whether to omit Pyret-only content entirely or
document it with a "deferred" badge. We chose **omit + central
registry** — see Phase D.

### C. Pre-translation: scribble-api aliases (optional)

If you're doing the macro rename eventually, drop `(define jayret-block
pyret-block)` etc. into `scribble-api.rkt` and `provide` them. The rename
in the translator becomes a no-op edit because both names already
resolve. We **reverted** these for v1 to keep the diff smaller; flip
back on later.

### D. Deferred-features registry

A single page (`src/deferred-from-pyret.scrbl`) lists every Pyret feature
that Jayret doesn't have a surface form for yet, each linked to its
**upstream Pyret docs** at `www.pyret.org/docs/latest/`. Stub structure:

```racket
@title[#:style '(toc) #:tag "Deferred_from_Pyret"]{Deferred from Pyret}
@subsection{Reactors}
… prose …
Upstream: @link["https://www.pyret.org/docs/latest/reactors.html"
                "Pyret docs: reactors"].
```

**Two gotchas:**

1. `#:style '(toc)` puts the section contents on a separate `…_features.html`
   subpage; the named `Deferred_from_Pyret.html` is just the TOC stub. WebFetching
   the stub looks "empty" — fetch the subpage to see the actual content.
2. `@secref["Deferred_from_Pyret"]` only resolves if you set
   `#:tag "Deferred_from_Pyret"` explicitly on the title. Scribble's
   auto-generated tag doesn't always match the obvious name.

Update the rest of the docs to redirect Pyret references that are now
in the registry:
`@secref["s:reactors"]` → `@secref["Deferred_from_Pyret"]`.

### E. Bulk code-block translation

Drive the translator over the file set:
```
node tools/pyret2jayret.mjs --in-place \
  src/lang/*.scrbl src/tour.scrbl \
  src/getting-started.scrbl src/language-concepts.scrbl \
  src/glossary.scrbl src/style-guide.scrbl \
  src/trove/*.scrbl src/builtin/*.scrbl src/platforms/*.scrbl
```

Run the build. **Expect failures.** We hit two structural issues that
the translator's self-tests didn't catch:

- **Tuple-bindings** (`{x; y; z} = {…}`) — the translator's
  `printBindingDecl` path didn't recognize them, emitted an unbalanced
  `{`, and Scribble swallowed the next macro's `}` trying to balance.
  Detect tuple-binding nodes explicitly and emit a TODO comment with the
  RHS, no LHS.
- **`@Check` collision with Scribble at-reader** — see Phase A; the
  `@` → `@"@"` rewrite fixes it.

### F. Prose rebrand (Pyret→Jayret in text)

Build a Scribble-aware substitution script (`tools/prose-rebrand.py`):

- `Pyret` (standalone word, no hyphen/alphanum on either side) → `Jayret`
- `pyret` (same, plus not preceded by `@`) → `jayret`
- `.arr` (file extension) → `.jrt`
- `code.pyret.org` → `jayret-lang.github.io/code`
- `www.pyret.org` → `jayret-lang.github.io`
- `pyret.org` (bare) → `jayret-lang.github.io`

**The script must be macro-aware**, not just regex-based:

- Track `@macro{…}` invocations with balanced-brace counting. Skip the
  bodies of code/identifier macros (`pyret-block`, `pyret`, `pyret-id`,
  `pyret-method`, `pyret-header`, plus `code`, `bnf`, `justcode`,
  `seclink`, `secref`, `xref`, `image`, `include-section`, `a-id`,
  `a-app`, …). Recurse into other macro bodies as prose.
- Treat `@(racket-expr)` (Racket-in-Scribble) as opaque — apply URL
  substitutions only, no rebrand. Otherwise you rewrite
  `(pyret opname)` inside `@(define (test-index-tag opname) …)` and
  break the Racket helper.
- **Don't** skip `@verbatim{…}` — it holds simulated runtime output
  where `.arr` paths and error-message text should track Jayret reality.

**Phrases you'll need to hand-restore.** The aggressive rebrand
*correctly* turns "Pyret runtime" into "Jayret runtime" and similar in
most places, but it also rewrites:

- `"variant of Pyret"` → `"variant of Jayret"` — wrong (Jayret is a
  variant of Pyret by definition).
- The `deferred-from-pyret.scrbl` page (Pyret as "the upstream
  language") becomes self-referential nonsense.
- Banner copy that talks about Pyret-the-historical-origin.

Hand-fix `index.scrbl`'s "variant of Pyret" line and rewrite
`deferred-from-pyret.scrbl` post-pass — there's nothing the regex can do
about these in general.

### G. Broken-xref cleanup

After Phase B + E, Scribble warns about cross-references whose targets
no longer exist (archived sections). They're warnings, not errors, but
they're noise on the deployed site. Three patterns:

1. **Section moved to archive** — redirect the link to the
   deferred-features page, or drop the link and rephrase ("Reactors do
   not yet have a Jayret surface syntax — see `Deferred from Pyret`").
2. **Section deleted with no replacement** — drop the link, keep the
   prose.
3. **Pre-existing broken xref upstream** — fix while you're in there if
   it's obvious. We had `@pyret-id["string" "String"]` with swapped/wrong
   args; the right form was `@pyret-id["String" "strings"]`.

### H. URL canonicalization

The Jayret playground deploys to **`jayret-lang.github.io/code`** —
GitHub Pages path of the `jayret-lang/code` repo. *Not* a
`code.jayret.org` subdomain.

Our prose-rebrand script's first version emitted
`code.pyret.org → code.jayret.org` — wrong. Fix is one line in the
script and one `sed -i` over `src/`. The local clone directory
`code.jayret.org/` keeps its name (it's the on-disk path for the
`jayret-lang/code` repo; renaming it breaks
`jayret-parley-vscode/build`'s relative symlink).

### I. Build infrastructure fixes

Inherited from the Pyret prefix and worth fixing:

- **Encoding warning** — the late `<head>` triggers
  *"meta tag attempting to declare the character encoding declaration was
  found too late"* and stalls page load. Put `<meta charset="utf-8">`
  as the very first thing after `<!doctype html>`.
- **Dead MathJax CDN** — upstream pointed at
  `http://cdn.mathjax.org/mathjax/latest/MathJax.js`. The host stopped
  serving that URL years ago. Failed-load timeouts make the page take
  "ages" to load. Drop the script if MathJax isn't actually used
  (`grep -l MathJax build/**/*.html` to confirm).
- **Favicon** — add a `<link rel="icon" …>` and copy a real PNG into
  the build (we used `jayret-lang-landing`'s `favicon.png`).
- **WIP banner** — `<style>` + `<div>` injected by the build's prefix
  mechanism. CSS overrides push `.tocset`, `.navsettop`, `.versionbox`,
  `.maincolumn` down by the banner height with `!important`. Copy from
  `src/myprefix.html` (or `dcic-world.org/templates/dcic.html` which now
  has the same pattern).

### J. Verification

Local:
```
nix-shell -p racket --run "make"      # build (or python3 build.py for DCIC)
grep -E 'broken|Error|scrbl:|make: \*\*\*' <build-output>
```
Headless render to compare layout against baseline:
```
cd build/docs && python3 -m http.server 8767 &
chromium --headless=new --disable-gpu --no-sandbox \
  --window-size=1280,900 --screenshot=/tmp/idx.png \
  http://localhost:8767/
```
Final grep sweep for residue:
```
grep -rn '\.arr\|code\.pyret\.org\|code\.jayret\.org\|@pyret{check:}\|@pyret{where:}' src/
```

### K. Deploy and monitor

Push to the deploy branch (`horizon` for jayret-docs, `main` for DCIC).
For jayret-docs:
```
gh run watch <ID> --repo jayret-lang/docs
```
For DCIC the `docs/` output is committed directly; verify
`https://jayret-lang.github.io/dcic/` reflects the new commit within ~30s.

### L. Track what's left in PARITY.md

A repo-root tracker is more useful than a hundred TODOs scattered through
prose. Categories that surfaced for us:

- Screenshots needed (Pyret-era screenshots removed; Jayret captures
  pending).
- Macro rename, if still deferred.
- Translator-flagged TODOs by category (intentional bad-ex,
  meta-placeholders, parser-unsupported forms).
- Archived sections worth porting eventually.
- Pre-existing build warnings (so they don't get blamed on the
  migration).

## Adapting this playbook for DCIC

Most of the conceptual work transfers; the tooling needs swaps:

1. **Phase A** (translator). DCIC's code blocks are fenced ```` ```pyret ```` /
   ```` ```python ```` in Markdown, not Scribble macro bodies. The
   `rewriteScribble` walker in `pyret2jayret.mjs` is the part to rewrite
   — find fenced blocks tagged `pyret` (and the bilingual blocks DCIC has
   that show parallel Pyret + Python), translate the body, keep the
   fence. The CST → Jayret printer is reusable verbatim (it just emits a
   string). DCIC has no `@`-reader, so the `@` → `@"@"` escape is *not*
   needed and would break things — strip it.
2. **Phase F** (prose-rebrand). The `@macro{…}` walker doesn't apply;
   Markdown is flat. Substitute over the whole file. Be careful about
   substituting inside fenced ```` ```python ```` blocks (DCIC has both
   languages side-by-side) — Python blocks should stay Python.
3. **Phase H** (URLs). Same map.
4. **Phase I** (build infra). The banner is already there
   (`templates/dcic.html`). The Markdown→HTML pipeline doesn't have the
   late-encoding bug (Pandoc writes a proper `<head>`), and there's no
   MathJax dead-CDN in DCIC's template — it uses
   `cdnjs.cloudflare.com`. Mainly: pick a copy that reflects DCIC's
   in-progress state vs the docs site's.
5. **Phase D** (deferred-features registry). DCIC's structure is
   chapter-based; a single "deferred-from-pyret" page may not be the
   right shape. Consider a per-chapter "(not in the Jayret edition)"
   callout or a global appendix.
6. **The macro rename** is a non-issue (no macros in Markdown).

## Gotchas we hit (one-liners)

- Pyret tokenizer drops comments — pre-extract or you lose them.
- Pyret parser rejects bare unary `-` at expression start.
- Scribble at-reader interprets `@FOO` in macro bodies — escape as `@"@"`.
- `@pyret{}}` is empty-body + stray `}`; write `@pyret{@"}"}`.
- `@(racket-expr)` is Racket-in-Scribble; substitution must skip it.
- `git checkout` over a previously-`mv`'d file resurrects it from HEAD;
  re-check that scope-pruned moves "stuck".
- `code.pyret.org` does *not* map to `code.jayret.org` (no subdomain).
- `#:style '(toc)` titles put content on a subpage, not the named anchor
  page — `Deferred_from_Pyret.html` is a stub; the real content is in
  `Deferred_features.html`.
- `@secref` to a `#:style '(toc)` page needs an explicit `#:tag`.
- The local `code.jayret.org/` *directory* keeps its legacy name even
  though the URL doesn't exist.

## Memory pointers

`/home/artem/.claude/projects/-home-artem-Dev-pyret-pyret-lang/memory/`:

- `jayret-project-overview.md` — the 5 repos and what they do.
- `jayret-local-paths.md` — local clones, branches, push refspecs.
- `pyret-frontend-amd-shim.md` — the AMD shim pattern for reusing
  Pyret's tokenizer/parser from Node.
- `jayret-repo-naming.md` — short generic names under
  `jayret-lang/` (`docs`, `code`, not `jayret-docs`).
- `git-remote-ssh.md` — rewrite HTTPS remotes to SSH before pushing on
  NixOS.
