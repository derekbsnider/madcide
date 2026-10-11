# common.sh — what madcide's scripts share; each sources it.
#
#   here      madcide's top directory
#   madc      MADC, the madc to use, as a command (default: madc on PATH;
#             "wine <madc folder>/bin/madc.exe" for the Windows one)
#   madc_prog the madc program alone (absolute when MADC names a directory),
#             madc_pre the command words before it ("wine " or "")
#   exe       the executable suffix of madc's platform ("" or ".exe")
#   platform  madc's platform as madc's test fixtures name it: linux,
#             darwin or win64
#   baselib   the file name of madcide's base as a library on that platform:
#             libmadcide.so, libmadcide.dylib, madcide.dll (the name a
#             product's "libs": ["madcide"] opens)
#   madc_bindir
#             the directory holding the madc program
#   madc_src_setup
#             sets madc_src, a madc source checkout at madcide.json's madc
#             (MADC_SRC, default madc-src/): its scripts/run_tests.sh is the
#             fixture protocol madcide's tests follow, run as it is
#   madc_paired
#             MADC_PACKAGE, the madc release package madcide's packages
#             carry, checked to be the madc that builds them (madc_pkg,
#             madc_ver)
#   madc_unpack PACKAGE ROOT
#             a madc release package unpacked into ROOT, madc's folder layout
#   refresh_sums DIST FILE...
#             DIST/SHA256SUMS's lines for the packages just made
#   plain_modes DIR
#             DIR's tree with the modes a package installs
#   capped SECONDS COMMAND...
#             COMMAND under a wall-clock and a CPU limit

here=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
madc=${MADC:-madc}

# The madc program is the command's last word; one with a directory becomes
# absolute, since the scripts change directory.
madc_prog=${madc##* }
madc_pre=
[ "$madc_prog" != "$madc" ] && madc_pre="${madc% *} "
case "$madc_prog" in
/*|[A-Za-z]:*) ;;
*/*) madc_prog=$(cd "$(dirname "$madc_prog")" && pwd)/$(basename "$madc_prog")
     madc="$madc_pre$madc_prog" ;;
esac
exe=
case "$madc_prog" in
*.exe) exe=.exe ;;
esac
if [ -n "$exe" ]; then
	platform=win64 baselib=madcide.dll
elif [ "$(uname -s)" = Darwin ]; then
	platform=darwin baselib=libmadcide.dylib
else
	platform=linux baselib=libmadcide.so
fi

# The directory holding the madc program ("" = madc is not found).
madc_bindir() {
	local p=$madc_prog
	case "$p" in
	*/*) ;;
	*) p=$(command -v "$p") || return 0 ;;
	esac
	(cd "$(dirname "$p")" 2>/dev/null && pwd)
}

# madc_src_setup — madc_src, the madc source checkout whose test runner and
# fixture gates madcide's tests use (CI checks out madcide.json's release
# there; a developer points MADC_SRC at their madc tree).
madc_src_setup() {
	madc_src=${MADC_SRC:-$here/madc-src}
	if ! madc_src=$(cd "$madc_src" 2>/dev/null && pwd) || [ ! -f "$madc_src/scripts/run_tests.sh" ]; then
		echo "$(basename "$0"): no madc source at ${MADC_SRC:-$here/madc-src} (its scripts/run_tests.sh) — set MADC_SRC" >&2
		return 1
	fi
}

# refresh_sums DIST FILE... — DIST/SHA256SUMS gets these files' lines and
# keeps every other package's (each platform packages on its own host).
refresh_sums() {
	(
		cd "$1" || exit 1
		shift
		touch SHA256SUMS
		for f in "$@"; do
			awk -v f="$f" '$2 != f' SHA256SUMS > SHA256SUMS.tmp
			mv SHA256SUMS.tmp SHA256SUMS
		done
		if command -v sha256sum > /dev/null; then
			sha256sum "$@" >> SHA256SUMS
		else
			shasum -a 256 "$@" >> SHA256SUMS
		fi
	)
}

# madc_paired — MADC_PACKAGE, the madc release package every madcide
# package carries (its .zip, .tar.gz or .deb), as madc_pkg (absolute), and
# its version as madc_ver: the release of the madc that builds madcide,
# since madcide links the libraries it ships with.
madc_paired() {
	madc_pkg=${MADC_PACKAGE:-}
	if [ -z "$madc_pkg" ] || [ ! -f "$madc_pkg" ]; then
		echo "$(basename "$0"): MADC_PACKAGE names no madc release package ('$madc_pkg'): madcide's packages carry madc" >&2
		return 1
	fi
	madc_pkg=$(cd "$(dirname "$madc_pkg")" && pwd)/$(basename "$madc_pkg")
	# shellcheck disable=SC2086
	madc_ver=$($madc --version | sed -n 's/^madc \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p' | head -1)
	local pv
	pv=$(basename "$madc_pkg" | sed -n 's/^madc[-_]\([0-9]*\.[0-9]*\.[0-9]*\)[-_.].*/\1/p')
	if [ -z "$madc_ver" ] || [ "$pv" != "$madc_ver" ]; then
		echo "$(basename "$0"): MADC_PACKAGE is madc '$pv', the madc building madcide ($madc) is '$madc_ver'" >&2
		return 1
	fi
}

# madc_unpack PACKAGE ROOT — a madc release package unpacked into ROOT in
# madc's folder layout (bin/, lib/, share/, its notices), the layout its
# zip and tarballs have. A .deb's usr/ is that layout but for its libraries
# in the system's multiarch directory (usr/lib/<triplet>/): they move up to
# lib/, where madc's programs look for them ($ORIGIN/../lib).
madc_unpack() {
	local pkg=$1 root=$2 t top d
	t=$(mktemp -d)
	case "$pkg" in
	*.zip) unzip -q "$pkg" -d "$t/x" ;;
	*.tar.gz) mkdir "$t/x" && tar -xzf "$pkg" -C "$t/x" ;;
	*.deb) dpkg-deb -x "$pkg" "$t/deb" ;;
	*) echo "madc_unpack: $pkg is not a madc release package (.zip, .tar.gz, .deb)" >&2
	   rm -rf "$t"; return 1 ;;
	esac
	mkdir -p "$root"
	if [ -d "$t/deb" ]; then
		cp -R "$t/deb/usr/." "$root/"
		for d in "$root"/lib/*-linux-gnu; do
			[ -d "$d" ] || continue
			mv "$d"/* "$root/lib/"
			rmdir "$d"
		done
	else
		top=$(ls -A "$t/x")
		if [ "$(printf '%s\n' "$top" | wc -l | tr -d ' ')" != 1 ] || [ ! -d "$t/x/$top" ]; then
			echo "madc_unpack: $pkg does not hold one folder" >&2
			rm -rf "$t"; return 1
		fi
		cp -R "$t/x/$top/." "$root/"
	fi
	rm -rf "$t"
	if [ ! -f "$root/bin/madc$exe" ]; then
		echo "madc_unpack: $pkg holds no bin/madc$exe" >&2
		return 1
	fi
}

# plain_modes DIR — directories 0755 (a setgid bit inherited from the
# checkout cleared first, since a numeric mode keeps it), executables 0755,
# every other file 0644: what a package installs, whatever the checkout's
# modes and umask were.
plain_modes() {
	find "$1" -type d -exec chmod g-s {} +
	find "$1" -type d -exec chmod 0755 {} +
	find "$1" -type f -perm -0100 -exec chmod 0755 {} +
	find "$1" -type f ! -perm -0100 -exec chmod 0644 {} +
}

# capped SECONDS COMMAND... — COMMAND under a wall-clock limit (coreutils'
# timeout; gtimeout where Homebrew's coreutils provides it, as on a Mac) and
# the same CPU limit where the shell can set one (Git Bash on Windows cannot),
# so a hang fails instead of running on.
tmo=$(command -v timeout || command -v gtimeout || true)
capped() {
	if [ -z "$tmo" ]; then
		echo "$(basename "$0"): no timeout command (coreutils: timeout, or gtimeout on a Mac)" >&2
		return 124
	fi
	local s=$1
	shift
	(ulimit -t "$s" 2> /dev/null || true; "$tmo" "$s" "$@")
}
