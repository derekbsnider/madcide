# Changelog

madcide's history before 0.7.0 is in madc's changelog, under the releases that
shipped it inside the madc tree.

## [Unreleased]

## [0.9.0] — 2026-10-23

The shared-faces release, paired with madc 0.106.0 (`madcide.json`): three
rules madcide kept its own copy of — a path's extension, stem and parent
directories; the user configuration directory; a project manifest's read and
write — are deleted, and madcide calls madc's one owner for each. Each move
fixes a place the copy had diverged. madcide also moves onto madc 0.106.0's
module model: git, Markdown and the web UI target are imported by name instead
of probed for.

### madcide imports madc's capabilities as modules

madcide says `import git;`, `import markdown;` and `import ui_web;` — madc
0.106.0's self-describing modules, in place of the former availability probes:
the git views and `%git`, the Markdown renderer behind Help and Markdown
Preview, and the window (`ui::WEB`). The `git::available()` and
`markdown::available()` checks and their "module not installed" messages are
gone — git and Markdown are open wherever madcide runs, and the window opens
through `ui_web`. On Linux the packages now DEPEND on WebKitGTK 6.0 and GTK 4
rather than recommend them: an imported module opens at program start, so the
terminal face loads `ui_web`'s libraries too, not only the window. Gate: the
gui lane (`scripts/run_tests.sh --gui`).

### Paths go through madc's path faces

`madc::path_drop_extension` gives `{base}`, the layout, events and fresh
manifest paths and the default output; `madc::path_stem` gives the program's
name and the key-profile names; `madc::path_make_parents` makes the directory
before `settings.json` and `recent.json` are written. The old extension split
cut at the last dot of the whole path, so a dot in a directory ate the name:
`proj.d/myproj`'s layout is now `proj.d/myproj.layout` (it was `proj.layout`),
and the directory-make no longer grows a Windows absolute path from `.`. Gate:
`tests/testmadcide` (`layout-path:`); `scripts/check-madcide-single-owners.sh`
is red on a hand-rolled extension split in madcide's dialect code.

### The user configuration directory is madc's

madc owns the one lookup rule — `$XDG_CONFIG_HOME`, `%APPDATA%` on Windows,
`~/.config` — and `madcide_config_dir` keeps only its `MADCIDE_CONFIG_DIR`
override and then calls `madc::user_config_dir` with the product's name. On
Windows the madcide copy had looked only in `$HOME/.config`; the directory now
honours `%APPDATA%`. Gate: `scripts/check-madcide-single-owners.sh` is red on a
read of `XDG_CONFIG_HOME` or `APPDATA` in madcide's dialect code.

### Project manifests are read and written by madc

The project layer calls madc's one reader and writer:
`madc::project_manifest_read` for load and the reload after each edit,
`madc::project_manifest_create` / `_add_tu` for the materialized manifest (an
existing file is never overwritten), `_add_tu` / `_remove_tu` for the file add
and delete, `_set_kind` for the kind toggle, `madc::project_default_output` for
the build rows, `madc::project_events_path` for the memory file, and
`madc::project_kind` codes with `madc::project_kind_name`. Against madc's reader
the madcide copy had differed: a TU now resolves against the manifest's
directory, the default output of `foo.prj.json` is `foo.prj`, `"output"`
resolves against the manifest, an added file is stored resolved, and an unknown
kind word carries madc's reason instead of becoming console. Gate:
`tests/testmadcide` (`proj-faces-read` / `-add` / `-output` / `-kind`,
`proj-addcur-nofile`, `proj-bad`); `scripts/check-madcide-single-owners.sh` is
red on a manifest parsed, stringified or given a kind word in madcide.

## [0.8.0] — 2026-10-15

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

### Syntax colour in the REPL pane

The REPL pane paints code in colour, as the CLI's REPL does. The transcript's
code — a printed line (`:%p`), a `%type` type, and each taken entry echoed
into it — is painted by madc's own painter (`madc::theme_paint`) over the
scheme the IDE loads through the CLI's theme reader (`madc::theme_styles`), so
a colon command's output is coloured exactly as `madc -i` colours it; the
painter's SGR becomes the terminal screen's coloured runs. The input, as it is
typed, keeps the editor's own span colouring (`madc::lex_spans`). Gate:
`tests/testmadcide_repl` (the `repl colon colour:` line).

### Packages carry the tested build

`MADCIDE_BUILD` names what `scripts/build.sh -o DIR` already built, and
`package_linux.sh`, `package_macos.sh` and `package_windows.sh` package that
build as it is instead of compiling madcide a second time (without it they
build first, as before). A build missing the program, its base library or the
plugins, or older than a source under `tools/`, is refused. CI's Linux,
Ubuntu 22.04 and macOS jobs package the build their tests ran.

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
