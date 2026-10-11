#!/bin/bash
# check-one-style-vocabulary.sh — madcide's half of madc's ui RENDER STYLE
# gate (madc's scripts/check-one-style-vocabulary.sh: one style, one spec
# parser — include/madcdis/ui_style.h — no renderer vocabulary of its own).
#
# A highlight span reaches every renderer as the loaded scheme's style SPEC
# (`keyword bold`, `string cyan` — profiles/*.theme): a span row is
# {s, e, c}, and the engine's renderers read c through ui_style_of. Until
# 2026-09-08 madcide's converter also wrote each span's SEMANTIC class
# ("cls") and the web renderer styled that from a palette of its own, so the
# window never showed the scheme the terminal showed.
#
# Rule: madcide's dialect code neither writes nor reads a span's class name
# — no `"cls": ` field, no `find("cls")`.
#
# Negative control: a synthetic violation of each kind must FAIL the scan,
# else the gate itself is broken and we fail loudly.

set -u
cd "$(dirname "$0")/.." || exit 2

PATTERN='find\("cls"\)|"cls": '

scan() {
	# $@ = files; prints violations, returns 0 when clean.
	grep -nE "$PATTERN" "$@" /dev/null
	test $? -ne 0
}

# --- negative controls -------------------------------------------------------
tmp=$(mktemp)
printf 'hs[] = { "s": s, "e": e, "cls": cls, "c": c };\n' > "$tmp"
if scan "$tmp" >/dev/null 2>&1; then
	rm -f "$tmp"
	echo "check-one-style-vocabulary: NEGATIVE CONTROL FAILED — the scan did not catch a class-name span field" >&2
	exit 2
fi
printf 'var ci = row.find("cls");\n' > "$tmp"
if scan "$tmp" >/dev/null 2>&1; then
	rm -f "$tmp"
	echo "check-one-style-vocabulary: NEGATIVE CONTROL FAILED — the scan did not catch a class-name span read" >&2
	exit 2
fi
rm -f "$tmp"

# --- the tree ------------------------------------------------------------------
files=$(git ls-files --cached --others --exclude-standard 'tools/*.inc' 'tools/*.mad' 'tools/**/*.inc' 'tools/**/*.mad' 'tools/madcide/include/madcide/*')
# shellcheck disable=SC2086
if ! out=$(scan $files 2>&1); then
	echo "check-one-style-vocabulary: a span row read or written by class name instead of its style spec:" >&2
	echo "$out" >&2
	echo "  -> rows are {s, e, c}; the engine reads c through ui_style_of" >&2
	exit 1
fi
echo "check-one-style-vocabulary: OK — madcide's span rows carry the style spec, never a class name (negative controls bite)"
