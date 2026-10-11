#!/bin/bash
# run_tests.sh — run madcide's tests with a madc, through madc's own test
# runner.
#
#   scripts/run_tests.sh [--gui] [RUNNER ARGS...]
#
#   MADC      the madc to run them with, as a command (default: madc on PATH;
#             "wine <madc folder>/bin/madc.exe" for the Windows one)
#   MADC_SRC  a madc source checkout at madcide.json's madc (default
#             madc-src/): its scripts/run_tests.sh runs the tests, as it is.
#             madcide's tests follow madc's fixture protocol (.expect, .env,
#             .timeout, .<domain>_skip, .<domain>_expect, ...; madc's
#             .claude/rules/test-fixtures.md), so the protocol has one owner
#   --gui     the window tests (tests/gui/), for a display: run this under
#             xvfb-run where there is none
#   RUNNER ARGS  passed on: test names or globs, --exe, --obj, ...
#
# The tests run from madcide's top directory (a test includes
# ../tools/madcide/...). madc's platform picks the fixtures' domains
# (MADC_SKIP_EXT, unless set): win64 and win (wine64 under wine) for the
# Windows madc, darwin, libcxx and darwin-<arch> on a Mac. madcide's user
# configuration and plugin path are the developer's, never the suite's:
# MADCIDE_CONFIG_DIR names a directory that does not exist (a test that
# needs one names its own in its .env), and MADCIDE_PLUGIN_PATH is unset.
set -u
. "$(dirname "$0")/common.sh"
madc_src_setup || exit 1
cd "$here" || exit 1
if [ "${1:-}" = "--gui" ]; then
	export MADC_TEST_DIR=tests/gui
	shift
fi
mkdir -p tmp
export MADCIDE_CONFIG_DIR="$here/tmp/madcide-no-config"
unset MADCIDE_PLUGIN_PATH
export MADC_BIN=$madc_prog
if [ -n "$madc_pre" ]; then
	export MADC_WRAPPER=${madc_pre% }
fi
case "$platform" in
win64)
	if [ -n "$madc_pre" ]; then
		export MADC_SKIP_EXT="${MADC_SKIP_EXT:-win64 wine64}"
	else
		export MADC_SKIP_EXT="${MADC_SKIP_EXT:-win64 win}"
	fi ;;
darwin) export MADC_SKIP_EXT="${MADC_SKIP_EXT:-darwin libcxx darwin-$(uname -m)}" ;;
esac
exec bash "$madc_src/scripts/run_tests.sh" "$@"
