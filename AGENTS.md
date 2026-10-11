# Agent Instructions — madcide

The briefing for any AI coding agent working on this repository. Claude Code
reads it through `CLAUDE.md` (`@AGENTS.md`); other tools read this file.

## What this is

madcide is the madc IDE: an editor, a REPL and a window over madc's engine,
written in the madc dialect (`tools/madcide/`, `tools/texteditor/`), plus the
VS Code extension that talks to it (`tools/vscode-madcide/`). It left the
madc repository with its history in madc's split arc
(`docs/plans/2026-10-09-madc-madcide-split-arc.md` in madc).

madcide depends on madc the way any program depends on a library release:

    madc (compiler + engine)  ←pin—  madcide (IDE)  ←pin—  Chthonia (a face)

- `madcide.json`'s `"madc"` names the madc release madcide is built for. CI
  fetches that release, builds madcide with it, runs madcide's full suite
  against it on every platform, and packages madcide WITH it: every package
  stands alone (one download, one install).
- madcide's version is its own (`tools/madcide/madcide_version.h`): its minor
  is the paired madc's minor − 97 (madcide 0.7.0 ↔ madc 0.104.0).
- The engine madcide consumes — `ns_ui` / `ns_ui_web`, `include/madcdis/`,
  `madc::parse_*`, sessions, the module loader, the document component, the
  ex core, the command registry — is madc's versioned public surface. A
  missing or wrong engine capability is fixed IN MADC (its own commit, gates
  and release), never worked around here. madc keeps no madcide-specific
  code path, and madcide carries no copy of an engine rule.

## The rules

madcide is madc-dialect application code, so madc's rules for dialect code
apply as written. They live in the madc repository; read them there, never
fork them here:

| Rule (madc `.claude/rules/`) | What it governs here |
|------------------------------|----------------------|
| `value-first.md`             | zero includes / `using` / `std::` beyond the program's own modules; `var` over `std::string`; output through `print` / `println` / `format` |
| `dialect-literals.md`        | build objects with literals (gated: `scripts/check-dialect-literals.sh`) |
| `dialect-lean.md`            | the dialect surface never depends on C++ headers or std::string |
| `enum-over-strings.md`       | every discriminator an enum; text only at an input boundary, converted once |
| `thread-safety.md`           | every addition states its contract; shared mutation through the hub |
| `design-principles.md`, `no-parallel-implementations.md`, `helper-methods.md`, `fix-what-you-find.md` | one owner per concern; search before adding a helper; a defect found is a defect fixed |
| `testing-fulltest.md`        | name the tier: targeted per change, the full suite per batch, every platform before a release |
| `test-fixtures.md`           | the fixture protocol madcide's tests follow (madc's runner runs them) |

## Building and testing

The scripts take the madc to use from `MADC` (a command; default `madc` on
PATH) and madc's source, for its test runner, from `MADC_SRC` (default
`madc-src/`, a checkout of madc at the pinned release).

```bash
bash scripts/build.sh                 # build/madcide, its base library, the plugins
bash scripts/run_tests.sh [NAMES]     # the suite, by madc's runner (tests/)
xvfb-run -a bash scripts/run_tests.sh --gui    # the window tests (tests/gui/)
bash scripts/gates.sh [--static]      # the static gates, then the editor on a pty
```

Tiers: targeted tests per change; `scripts/gates.sh --static` plus the
touched tests per commit; the whole suite and the pty gates per batch; CI's
every platform before a release. Scratch files go in `tmp/` (gitignored); a
test removes what it creates.

## Committing

- Branches: `main` is released; work on feature branches.
- Commit early; never clobber uncommitted work.
- A change that needs an engine change lands in madc first; madcide then
  bumps its `"madc"` pin.
