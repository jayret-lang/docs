# Jayret docs — parity work

Tracks known gaps between this site and the upstream
[brownplt/pyret-docs](https://github.com/brownplt/pyret-docs/) snapshot we
forked from, plus Jayret-specific follow-ups.

## Screenshots — Jayret captures needed

`src/platforms/platforms.scrbl` used six screenshots of the Pyret-era VS Code
extension and code.pyret.org workflow. They've been **removed** for now to
avoid showing Pyret branding; the prose has been left in place. We need
Jayret captures of:

- [ ] `vscode-install.png` — VS Code Marketplace listing for
      [`ulysses4ever.jayret-parley`](https://marketplace.visualstudio.com/items?itemName=ulysses4ever.jayret-parley)
      (formerly `PyretProgrammingLanguage.pyret-parley`).
- [ ] `vscode-open.png` — clicking on a `.jrt` file to open in the Jayret
      visual editor.
- [ ] `open-with.png` — VS Code "Open With…" context menu showing the choice
      between the visual editor and the plain-text editor.
- [ ] `open-with-default.png` — same menu with the "Set as default" affordance.
- [ ] `play-button.png` — the ▶ run-button on a `.jrt` tab in the plain-text
      editor.
- [ ] `split-run.png` — split-pane layout after a run, with the interactions
      area on the side.

When adding back: drop a Jayret PNG into `src/`, add the corresponding
`@image[…]` line in `platforms.scrbl`, remove the matching bullet here, and
update the `@margin-note` placeholder if all six are restored.

## Macro rename (deferred)

Translator currently leaves `@pyret-block`, `@pyret`, `@pyret-id`,
`@pyret-method` as-is. The plan was to switch them to `@jayret-block` etc.,
with pass-through aliases in `scribble-api.rkt` so both names resolve during
transition. We deferred to keep the migration diff readable.

To finish: re-add the aliases (see commit `577765d` for the pattern, then
reverted), flip the translator's macro-name rewrite back on
(`tools/pyret2jayret.mjs` `rewriteScribble`), re-translate the .scrbl files.

## Translator-flagged TODOs

After the Pyret→Jayret pass, ~40 macro bodies were left untranslated
(tagged `@; TODO(pyret2jayret): …`). Most are:

- **Intentional `bad-ex` snippets** (Pyret syntax shown as wrong on purpose).
  Leave as-is unless we want Jayret-flavored bad examples.
- **Meta-syntactic placeholders** (`<some-module>`, `<some-name>`) — these
  aren't valid Pyret either.
- **New-style `provide`/`include` forms** (`data *`, `module *`, `hiding`)
  that the phaseA Pyret parser doesn't accept.
- **`is-not==`, `is==`, and related strict-equality check operators** —
  recognized by the parser but the printer emits a TODO.

Grep `src/` for `TODO(pyret2jayret)` to see all sites.

## Archived sections (not in the v1 build)

Moved to `src/_archive/` so they can be revived:

- `Pyret-Tutorial/` — the Lander game tutorial. Off-topic for Jayret v1.
- `internals/` — Pyret runtime/FFI internals: stack frames, `runtime.scrbl`,
  `ffi-helpers.scrbl`, `running.scrbl`, `modules.scrbl` (the single-module
  JS format reference). Likely *not* worth porting since Jayret reuses the
  Pyret runtime unchanged — but if we ever want a "Jayret internals" page,
  this is the starting point.
- `libraries-archived.scrbl` — upstream-flagged historical libraries
  (`image-structs`, `world`). Re-include if Jayret keeps them.
- `reactors.scrbl` — Reactors API. Re-include when Jayret has reactor
  surface syntax (tracked under "Deferred from Pyret").

## Pre-existing build warnings (not regressions)

The build emits 8 `report-undocumented` warnings for `filesystem` module
exports (`exists`, `resolve`, `dirname`, `relative`, `is-absolute`, `join`,
`basename`, `create-dir`). These were there in the baseline upstream build.
Document the exports in `src/trove/filesystem.scrbl` or suppress per the
upstream `ignore[]` pattern.

## Deferred Pyret features (tracked separately)

See [`src/deferred-from-pyret.scrbl`](src/deferred-from-pyret.scrbl) for the
user-facing list of Pyret features without a Jayret surface syntax yet
(Reactors, Tuples, `sharing:`, refinement annotations,
fine-grained `provide`, mid-loop `return`, `while` loops, `use context`).
