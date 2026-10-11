#!/bin/bash
# check_install.sh — madcide installed, standing alone, run as a user runs it
# (Linux, macOS, Windows).
#
#   scripts/check_install.sh PREFIX
#
#   PREFIX  the installation: the folder holding bin/madcide — a tarball's
#           or the zip's folder, or /usr/lib/madcide where a .deb or .rpm
#           installs it. madcide's data is under share/madcide, or beside
#           the programs in bin\ on Windows (bin/madcide.exe).
#
# The controls move installed directories aside, so run it as their owner:
# under sudo for an installed .deb or .rpm.
#
# Each probe runs from a directory of its own with no user configuration
# and no library path, and each control must fail:
#   0. the installation carries its madc: bin/madc runs, and on Linux
#      madcide loads libmadc from PREFIX/lib; madcide's base library is in
#      madc's library directory (lib/, bin\ on Windows), where a product's
#      "libs": ["madcide"] is found;
#   1. madcide prints its usage line;
#   2. `-c check` over a C file that includes <stdio.h> is clean: madc's
#      installed headers and engine serve it [control: a syntax error is 1
#      problem, exit status 1];
#   3. the shipped plugins are installed, each with code carrying its built
#      library; View ▸ Key Bindings… is on the View menu and lists the six
#      key styles [control: the profiles hidden, it lists none];
#   4. where a pty is (Linux, macOS): the editor paints a file with its
#      profiles found [control: the profiles hidden, the rescue banner], and
#      saves and quits by JOE's keys from a foreign directory [control: the
#      profiles hidden, the rescue keys do].
set -u
. "$(dirname "$0")/common.sh"
if [ $# -ne 1 ] || [ ! -d "$1" ]; then
	echo "usage: $0 PREFIX" >&2
	exit 2
fi
prefix=$(cd "$1" && pwd)
if [ -f "$prefix/bin/madcide.exe" ]; then
	sfx=.exe data=$prefix/bin libdir=$prefix/bin lib=madcide.dll pty=0 linux=0
else
	sfx= data=$prefix/share/madcide libdir=$prefix/lib pty=1 linux=1 lib=libmadcide.so
	if [ "$(uname -s)" = Darwin ]; then
		linux=0 lib=libmadcide.dylib
	fi
fi
madcide=$prefix/bin/madcide$sfx
profiles=$data/profiles
plugins=$data/plugins
work=$(mktemp -d)
hidden=
restore() {
	[ -n "$hidden" ] && [ -e "$hidden.hidden" ] && mv "$hidden.hidden" "$hidden"
	rm -rf "$work"
}
trap restore EXIT
ok() { echo "check_install: ok — $1"; }
fail() { echo "check_install: FAIL — $1" >&2; exit 1; }
runenv=(env -u MADCIDE_PLUGIN_PATH -u LD_LIBRARY_PATH -u DYLD_LIBRARY_PATH "MADCIDE_CONFIG_DIR=$work/no-config")
# run ARG... — madcide from $work, no user configuration; output and status.
run() {
	(cd "$work" && capped 60 "${runenv[@]}" "$madcide" "$@") 2>&1
}
# hide DIR — DIR moved aside for a control; an installed package's
# directories are root's, so a control there runs as root.
hide() {
	mv "$1" "$1.hidden" 2> /dev/null || fail "cannot move $1 aside for its control (run as its owner: sudo for an installed package)"
	hidden=$1
}
unhide() { mv "$hidden.hidden" "$hidden"; hidden=; }
[ -x "$madcide" ] || fail "no executable $madcide"

# 0. its own madc, and madcide's base library beside madc's
out=$(cd "$work" && capped 60 env -u LD_LIBRARY_PATH -u DYLD_LIBRARY_PATH "$prefix/bin/madc$sfx" --version 2>&1)
case "$out" in
"madc "[0-9]*) ok "the installation carries its madc (${out%%$'\n'*})" ;;
*) fail "no madc of its own in $prefix/bin (got: $out)" ;;
esac
if [ "$linux" = 1 ]; then
	# ldd names it as found: <prefix>/bin/../lib/... through $ORIGIN.
	found=$(env -u LD_LIBRARY_PATH ldd "$madcide" | awk '$1 == "libmadc.so.0" { print $3 }')
	dir=$(cd "$(dirname "${found:-/nonexistent/x}")" 2>/dev/null && pwd)
	[ "$dir" = "$prefix/lib" ] || fail "madcide loads libmadc from '$found', not $prefix/lib"
	ok "madcide loads libmadc from its installation ($dir)"
fi
[ -f "$libdir/$lib" ] || fail "no $lib in $libdir (madcide's base, which a product links)"
ok "madcide's base library is in madc's library directory ($libdir/$lib)"

# 1. usage
out=$(run --help)
case "$out" in
*"usage: madcide"*) ok "madcide prints its usage line" ;;
*) fail "madcide --help printed no usage line (got: $out)" ;;
esac

# 2. -c check
printf '#include <stdio.h>\nint main(void) { printf("%%d\\n", 5); return 0; }\n' > "$work/ok.c"
printf '#include <stdio.h>\nint main(void) { return 0 }\n' > "$work/bad.c"
out=$(run ok.c -c check)
rc=$?
case "$rc:$out" in
0:*Problems*) ok "-c check over <stdio.h> is clean (exit status 0)" ;;
*) fail "-c check over <stdio.h> was not clean (exit status $rc: $out)" ;;
esac
out=$(run bad.c -c check)
rc=$?
case "$rc:$out" in
1:*"1 problem"*) ok "control: a syntax error is 1 problem (exit status 1)" ;;
*) fail "control broken: -c check over a syntax error (exit status $rc: $out)" ;;
esac

# 3. the plugins and the key styles
[ -f "$plugins/default/default.plugin" ] || fail "no default plugin at $plugins/default"
for pg in "$plugins"/*/; do
	pg=${pg%/}
	pn=$(basename "$pg")
	grep -q '"code"' "$pg/$pn.plugin" 2> /dev/null || continue
	ls "$pg/$pn".so "$pg/$pn".dylib "$pg/$pn".dll > /dev/null 2>&1 \
		|| fail "plugin '$pn' ships no built library beside its code ($pg)"
done
ok "the shipped plugins are installed, each with code carrying its library"
styles=("Chthonia" "VS Code" "Vim" "Emacs" "JOE" "Pico")
out=$(run ok.c -c "menushow View")
case "$out" in
*"Key Bindings"*) ok "the View menu has Key Bindings…" ;;
*) fail "the View menu has no Key Bindings… row (got: $out)" ;;
esac
out=$(run ok.c -c keystyle)
missing=
for s in "${styles[@]}"; do
	case "$out" in *". $s"*) ;; *) missing="$missing [$s]" ;; esac
done
[ -z "$missing" ] || fail "the Key Bindings list lacks$missing (got: $out)"
ok "the Key Bindings list names all ${#styles[@]} styles"
hide "$profiles"
out=$(run ok.c -c keystyle)
unhide
named=
for s in "${styles[@]}"; do
	case "$out" in *". $s"*) named="$named [$s]" ;; esac
done
[ -z "$named" ] || fail "control broken: the profiles hidden, the list still names$named"
ok "control: the profiles hidden, the Key Bindings list names no style"

# 4. the editor on a pty
if [ "$pty" = 1 ] && command -v python3 > /dev/null; then
	printf '// pk4probe — check_install editor probe\n' > "$work/pk4probe.mad"
	out=$(capped 90 "${runenv[@]}" python3 "$here/scripts/install_gate_pty.py" "$madcide" "$work/pk4probe.mad" pk4probe 2>&1)
	case "$out" in
	NORESCUE\ FILESEEN\ *) ok "the editor paints a file, its profiles found ($out)" ;;
	*) fail "the editor on a pty: expected 'NORESCUE FILESEEN' (got: $out)" ;;
	esac
	hide "$profiles"
	out=$(capped 90 "${runenv[@]}" python3 "$here/scripts/install_gate_pty.py" "$madcide" "$work/pk4probe.mad" pk4probe 2>&1)
	unhide
	case "$out" in
	RESCUE\ *) ok "control: the profiles hidden, the rescue banner ($out)" ;;
	*) fail "control broken: the profiles hidden but no rescue banner (got: $out)" ;;
	esac
	printf 'int main(void) { return 0; }\n' > "$work/sq.c"
	out=$(capped 120 "${runenv[@]}" python3 "$here/scripts/madcide_save_quit_pty.py" "$work/sq.c" 0b640b71 "$madcide" 2>&1)
	case "$out" in
	"SAVED EXITED rc=0 NORESCUE"*) ok "the editor saves and quits from a foreign directory ($out)" ;;
	*) fail "the editor did not save and quit from a foreign directory (got: $out)" ;;
	esac
	printf 'int main(void) { return 0; }\n' > "$work/sq.c"
	hide "$profiles"
	out=$(capped 120 "${runenv[@]}" python3 "$here/scripts/madcide_save_quit_pty.py" "$work/sq.c" 1311 "$madcide" 2>&1)
	unhide
	case "$out" in
	"SAVED EXITED rc=0 RESCUE"*) ok "control: the profiles hidden, the rescue keys save and quit ($out)" ;;
	*) fail "the profiles hidden, the rescue keys did not save and quit (got: $out)" ;;
	esac
fi
echo "check_install: PASS ($prefix)"
