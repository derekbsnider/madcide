#!/bin/bash
# build.sh — build madcide with a madc: the program, its base as a library,
# and the shipped plugins built by that program.
#
#   scripts/build.sh [-o DIR]
#
#   MADC     the madc to build with, as a command (default: madc on PATH;
#            "wine <madc folder>/bin/madc.exe" builds the Windows programs)
#   -o DIR   where they go (default build/):
#              madcide          the IDE (madcide.exe on Windows), AOT-
#                               compiled by madc from tools/madcide/madcide.mad
#              <baselib>        madcide's base (tools/madcide/madcide_base.mad)
#                               as the library a product built on madcide
#                               links: libmadcide.so, libmadcide.dylib or
#                               madcide.dll (scripts/common.sh)
#              plugins/         the shipped plugins, each with code built by
#                               that madcide (scripts/build_shipped_plugins.sh)
#
# madcide.json names the madc release madcide is built for; the madc used is
# whatever MADC names (CI fetches that release).
set -eu
. "$(dirname "$0")/common.sh"
out=$here/build
while [ $# -gt 0 ]; do
	case "$1" in
	-o) out=$2; shift 2 ;;
	*) echo "usage: $0 [-o DIR]" >&2; exit 2 ;;
	esac
done
mkdir -p "$out"
out=$(cd "$out" && pwd)
cd "$here"
# A Windows program binds madc's DLLs beside madc.exe: the built madcide.exe
# runs (to build the plugins) with that directory on its search path.
if [ -n "$exe" ]; then
	bindir=$(madc_bindir)
	export PATH="$bindir:$PATH"
	export WINEPATH="$bindir${WINEPATH:+;$WINEPATH}"
fi
echo "== madcide ($madc) =="
# shellcheck disable=SC2086
capped 600 $madc -o "$out/madcide$exe" tools/madcide/madcide.mad
echo "== $baselib =="
# shellcheck disable=SC2086
capped 600 $madc -shared -o "$out/$baselib" tools/madcide/madcide_base.mad
echo "== plugins =="
# shellcheck disable=SC2086
bash scripts/build_shipped_plugins.sh "$out/plugins" $madc_pre"$out/madcide$exe"
