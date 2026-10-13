# Changelog

madcide's history before 0.7.0 is in madc's changelog, under the releases that
shipped it inside the madc tree.

## [Unreleased]

## [0.8.0] — 2026-10-13

The live REPL release, paired with madc 0.105.0 (`madcide.json`): the REPL
pane follows an edit to the REPL buffer at once, and Restart and Run All runs
the whole buffer again in a fresh session.

### An edit to the REPL buffer takes effect at once

A colon command at the REPL pane that changes the REPL buffer (`:s`, `:a`,
`:d`, ...) hands the buffer's text before and after to the session
(`madc::session_edited`, madc 0.105.0's live reparse): each entry the edit
changed or added is read again as definitions only — a function is
redefined, a variable initialized again, no statement runs again — and what
the session refuses shows in the transcript and Problems. Gate:
`tests/testmadcide_repl` ("repl live").

### Restart and Run All

The Build menu's **Restart and Run All** (`replrunall`), and `%runall` typed in
the REPL, run the REPL buffer again in a fresh session, as Jupyter's Restart
Kernel and Run All Cells does: each entry as it was typed (one over several
lines included), shown in the transcript with what it printed and its value,
then the buffer's main when it defines one no entry called, with `[REPL]` and
the Program arguments as its argv (`madc::session_rebuild`, madc 0.105.0).
The REPL buffer stays as it is; F5 and `%run` keep running the editor's
buffer. Gate: `tests/testmadcide_replrunall`.

## [0.7.0] — 2026-10-12

madcide's first release as a standalone repository. madcide — the IDE and the
editor core it builds on — now lives at github.com/derekbsnider/madcide, its
history carried out of the madc tree, and ships its own packages, each carrying
the madc release it runs on.

### A repository of its own

- `madcide.json` pins the madc release madcide is built for (0.104.0);
  `tools/madcide/madcide_version.h` holds madcide's own version (0.7.0, its
  minor the paired madc's minor − 97) and home page, shown in Help ▸ About.
- `scripts/build.sh` builds madcide, its base library (`libmadcide.so` /
  `libmadcide.dylib` / `madcide.dll`) and the shipped plugins against the madc
  named by `MADC`; `scripts/stage.sh` is the one staging.
- `scripts/run_tests.sh` runs madcide's tests through madc's own test runner
  from a madc source checkout at the pinned release, so the fixture protocol
  keeps a single owner. `scripts/gates.sh` runs the static checks over this
  tree, madc's expect-twins gate over it, and the pty gates (quit,
  save-and-quit, scroll, golden screens).
- `.github/workflows/ci.yml` builds, gates, runs the suite and the window
  tests, and builds the packages and their installed checks on Linux (Ubuntu
  24.04 and 22.04), Windows (the suite under wine, packages on windows-latest)
  and macOS (arm64, x86_64), against the pinned madc; a `v*` tag drafts the
  release.
- `AGENTS.md` / `CLAUDE.md` point at madc's rules for dialect code; the README
  is madcide's own; MPL-2.0.

### Packages

Each release's packages stand alone: every one carries the paired madc release,
so one download is one install. `scripts/package_linux.sh`,
`scripts/package_windows.sh` and `scripts/package_macos.sh` build the Linux
`.deb` / `.rpm` and tarball, the Windows zip, and the macOS tarball. The `.deb`
and `.rpm` install madcide in its own `/usr/lib/madcide` folder (madc's folder
layout) with a `/usr/bin/madcide` link; on Ubuntu 24.04 and later they carry
AppArmor profiles (`madcide` and `madcide-madc`) naming the two programs that
open windows. `scripts/check_install.sh` and `scripts/check_apparmor.sh`
exercise an installed package as a user runs it, each probe against its own
negative control.

### Changed

Features madcide gained in the arc before the move:

- A **Symbols** view (View ▸ Symbols, docked beside the outline) lists the names
  the REPL session has defined, each with its type and value, as Thonny's
  Variables view does.
- **View ▸ Line Numbers** shows or hides the editor's line numbers in the
  terminal and the window alike.
- A buffer's parse is a madc document's: madcide reparses through
  `madc::doc_parse`.
- madcide runs on madc's own services — `madc --lsp`, `madc --mcp` and madc's
  ex core for the colon line; `madcide --line FILE` is `madc -i FILE`.
- `%git` runs the madcgit module's own verbs — the same implementation `madc -i`
  answers — in place of a copy written in the IDE.
- Colon mode in the REPL reaches the REPL buffer and the file buffers alike.
  madcide keeps a scratch `[REPL]` document per world; every entry the REPL
  session keeps and every file a `%load` keeps is appended to it. `:` typed in
  the REPL input runs a colon command there — on the REPL buffer by default,
  with `:b` / `:ls` / `:e` switching to a file buffer, a file switch shown in
  the editor — while `:` in the editor still works on the current file, and
  `:b REPL` from the editor brings the REPL pane up on its buffer.
