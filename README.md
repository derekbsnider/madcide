# madcide — the madc IDE

madcide is the IDE built on the running madc compiler: the editor holds a
live parse of your file, so diagnostics, the outline, syntax colour and the
status line come from the compiler's own state. One IDE, two faces: the
**terminal** and the **window** (a native window on Windows, macOS and Linux
through the platform webview). A REPL sits beside the editor; key styles
(VS Code, Vim, Emacs, JOE, Pico, Chthonia), colour schemes and plugins are
data files.

```sh
madcide file.c              # in the terminal
madcide file.c --gui        # in a window
madcide file.c --line       # madc's line mode: madc -i file.c
madcide file.c -c check     # one command, no surface: the problems and a verdict
```

[docs/madcide.md](docs/madcide.md) is the guide; `man madcide` the reference.

## Install

Each release's packages stand alone: every one carries the
[madc](https://github.com/derekbsnider/madc) release madcide is built on.

| Platform | Package |
|----------|---------|
| Ubuntu 24.04, 22.04 | `madcide_<ver>-1~ubuntu<release>_amd64.deb` — installs in `/usr/lib/madcide`, with `/usr/bin/madcide` |
| Fedora and other rpm systems | `madcide-<ver>-1.x86_64.rpm` |
| Any Linux | `madcide-<ver>-linux-x86_64.tar.gz` — unpack, run `bin/madcide` |
| macOS (Apple silicon, Intel) | `madcide-<ver>-macos-<arch>.tar.gz` — unpack, run `bin/madcide` |
| Windows | `madcide-<ver>-windows-x86_64.zip` — unzip, run `bin\madcide.exe` |

The window needs WebKitGTK 6.0 and GTK 4 on Linux (the packages recommend
them); the terminal needs neither.

## Build from source

madcide is built by madc: `madcide.json` names the madc release it is built
for.

```sh
MADC=/path/to/madc bash scripts/build.sh     # build/madcide, its base library, the plugins
```

Running from a checkout needs no build: `madc tools/madcide/madcide.mad file.c`.

## Tests

madcide's tests follow madc's fixture protocol and run through madc's own
test runner, from madc's source at the pinned release:

```sh
git clone --depth 1 --branch v$(sed -n 's/.*"madc": "\(.*\)".*/\1/p' madcide.json) \
    https://github.com/derekbsnider/madc madc-src
MADC=/path/to/madc bash scripts/run_tests.sh             # the suite
MADC=/path/to/madc xvfb-run -a bash scripts/run_tests.sh --gui    # the window tests
MADC=/path/to/madc bash scripts/gates.sh                 # the gates
```

## Layout

| Path | What |
|------|------|
| `tools/madcide/` | the IDE: its program, its base (`madcide_base.mad`, the library a product such as [Chthonia](https://github.com/derekbsnider/chthonia) links), the profiles, the shipped plugins, the plugin API headers |
| `tools/texteditor/` | the editor core's event follower |
| `tools/vscode-madcide/` | the VS Code extension that talks to a running madcide |
| `tests/`, `tests/gui/`, `tests/tui_golden/` | the suite, the window tests, the terminal's golden screens |
| `scripts/` | build, staging, packaging, the gates and the installed checks |

## License

Mozilla Public License 2.0 — see [LICENSE](LICENSE).
