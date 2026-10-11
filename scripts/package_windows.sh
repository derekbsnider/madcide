#!/bin/bash
# package_windows.sh — madcide's Windows zip, standing alone:
#
#   madcide-<ver>-windows-x86_64.zip   one folder, madcide-<ver>-windows-
#                                      x86_64\: the madc release it is paired
#                                      with (madc's zip) and madcide in it —
#                                      madcide.exe and madcide.dll beside
#                                      madc.exe, where they bind libmadc-0.dll,
#                                      madcide's data beside them. Unzip it,
#                                      run bin\madcide.exe.
#
#   scripts/package_windows.sh [-o DIST]
#
#   MADC          the Windows madc, as a command: "wine <madc folder>/bin/madc.exe"
#                 on Linux, <madc folder>/bin/madc.exe on Windows
#   MADC_PACKAGE  that madc's release zip, which the zip carries
#   -o DIST       where the zip goes (default dist/), its line in its SHA256SUMS
#
# The version is tools/madcide/madcide_version.h's. The zip is checked to
# hold exactly the staged files.
set -eu
. "$(dirname "$0")/common.sh"
dist=$here/dist
while [ $# -gt 0 ]; do
	case "$1" in
	-o) dist=$2; shift 2 ;;
	*) echo "usage: $0 [-o DIST]" >&2; exit 2 ;;
	esac
done
if [ "$exe" != .exe ]; then
	echo "package_windows.sh: MADC ($madc) is not a Windows madc (madc.exe)" >&2
	exit 1
fi
ver=$(sed -n 's/^#define MADCIDE_VERSION "\(.*\)"$/\1/p' "$here/tools/madcide/madcide_version.h")
[ -n "$ver" ] || { echo "package_windows.sh: no MADCIDE_VERSION in tools/madcide/madcide_version.h" >&2; exit 1; }
madc_paired || exit 1

work=$here/tmp/package-windows
rm -rf "$work"
mkdir -p "$work" "$dist"
dist=$(cd "$dist" && pwd)
bash "$here/scripts/build.sh" -o "$work/build"
folder=madcide-$ver-windows-x86_64
madc_unpack "$madc_pkg" "$work/zip/$folder"
MADCIDE_BUILD="$work/build" bash "$here/scripts/stage.sh" windows "$work/zip/$folder"
plain_modes "$work/zip"
zipname=$folder.zip
rm -f "$dist/$zipname"
(cd "$work/zip" && zip -q -r -X "$dist/$zipname" "$folder")
if ! diff <(unzip -Z1 "$dist/$zipname" | grep -v '/$' | LC_ALL=C sort) \
	  <(cd "$work/zip" && find . ! -type d | sed 's|^\./||' | LC_ALL=C sort) > "$work/diff"; then
	echo "package_windows.sh: $zipname does not hold exactly the staged files:" >&2
	cat "$work/diff" >&2
	exit 1
fi
refresh_sums "$dist" "$zipname"
echo "package_windows.sh: $dist/$zipname (madc $madc_ver)"
