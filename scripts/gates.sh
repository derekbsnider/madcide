#!/bin/bash
# gates.sh — madcide's gates: the static checks over its tree, then the
# editor driven on a real pty by the madc under test.
#
#   scripts/gates.sh [--static]
#
#   MADC      the madc under test, as a command (default: madc on PATH);
#             the pty gates run it as MADC_BIN
#   MADC_SRC  a madc source checkout at madcide.json's madc (default
#             madc-src/): madc's fixture gate (scripts/check-expect-twins.sh)
#             runs from it over madcide's tests
#   --static  the static checks alone (no madc run)
#
# Every gate carries its own negative control; the first red stops the run.
set -u
. "$(dirname "$0")/common.sh"
madc_src_setup || exit 1
cd "$here" || exit 1
static_only=0
[ "${1:-}" = "--static" ] && static_only=1

gate() {
	echo "== $* =="
	if ! "$@"; then
		echo "gates: RED — $*" >&2
		exit 1
	fi
}

for g in scripts/check-*.sh; do
	gate bash "$g"
done
gate bash "$madc_src/scripts/check-expect-twins.sh" "$here"
[ "$static_only" = 1 ] && { echo "gates: static checks green"; exit 0; }

export MADC_BIN=$madc_prog
for g in madcide_quit_gate.sh madcide_save_quit_gate.sh tui_scroll_gate.sh tui_golden_gate.sh; do
	gate bash "scripts/$g"
done
echo "gates: green"
