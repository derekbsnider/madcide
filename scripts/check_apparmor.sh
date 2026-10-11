#!/bin/bash
# check_apparmor.sh — the installed madcide's window under AppArmor's
# user-namespace restriction (Ubuntu 24.04 and later, by default).
#
#   scripts/check_apparmor.sh [SECONDS]
#
# After madcide's .deb is installed, as a user with sudo and a display
# (xvfb-run where there is none): the profile the .deb installs is loaded,
# madcide's window (--gui) starts its WebKit web process and stays up
# SECONDS (default 15) under it, and, the control, with the profile
# unloaded the web process never runs — WebKit's sandbox (bwrap) denied its
# user namespaces (LP: #2046844). The verdict is what ran, never how an exit
# status reads: a crash's core dump can hold the dying process past a
# timeout, which then reads as if it were still up. No core is written.
set -u
secs=${1:-15}
prof=/etc/apparmor.d/madcide
fail() { echo "check_apparmor: FAIL — $*" >&2; exit 1; }

[ -f "$prof" ] || fail "no $prof (the .deb installs it on Ubuntu 24.04 and later)"
[ "$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null)" = 1 ] \
	|| fail "the user-namespace restriction is off; this checks the window with it on"
sudo grep -q '^madcide ' /sys/kernel/security/apparmor/profiles \
	|| fail "the madcide profile is not loaded (the .deb's postinst loads it)"
echo "check_apparmor: ok — the package's profile is loaded"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf 'int main(void) { return 0; }\n' > "$work/aa.c"

# web_under PID: a WebKit web process runs beneath PID (WebKit starts it
# through bwrap, so it is a grandchild or deeper). comm is cut to 15 chars.
web_under() {
	ps -e -o pid=,ppid=,comm= | awk -v root="$1" '
		{ up[$1] = $2; name[$1] = $3 }
		END {
			for (p in name) {
				if (name[p] !~ /^WebKitWebProces/) continue
				for (q = up[p]; q > 1 && q != root; q = up[q]) ;
				if (q == root) exit 0
			}
			exit 1
		}'
}

# window — the installed madcide's window on aa.c for up to SECONDS, polled
# every half second: web (yes once its web process ran) and up (yes if it
# was still running at the end), then ended.
window() {
	local pid t=0
	web=no up=no
	( ulimit -c 0; exec madcide "$work/aa.c" --gui ) < /dev/null > "$work/ide.log" 2>&1 &
	pid=$!
	while [ $t -lt $((secs * 2)) ]; do
		kill -0 $pid 2>/dev/null || break
		[ $web = yes ] || ! web_under $pid || web=yes
		sleep 0.5
		t=$((t + 1))
	done
	[ $t -ge $((secs * 2)) ] && kill -0 $pid 2>/dev/null && up=yes
	kill $pid 2>/dev/null
	wait $pid 2>/dev/null
}

window
[ $web = yes ] || fail "under the profile the window never started its web process ($(tail -3 "$work/ide.log" | tr '\n' ' '))"
[ $up = yes ] || fail "under the profile the window ended by itself ($(tail -3 "$work/ide.log" | tr '\n' ' '))"
echo "check_apparmor: ok — under the profile the window started its web process and ran ${secs}s"

sudo apparmor_parser -R "$prof" || fail "could not unload $prof"
window
sudo apparmor_parser -r -T -W "$prof" || fail "could not load $prof again"
[ $web = no ] || fail "control: without the profile the web process ran too, so this check cannot see the restriction"
echo "check_apparmor: ok — control: without the profile the web process never ran ($(tail -1 "$work/ide.log"))"
echo "check_apparmor: PASS"
