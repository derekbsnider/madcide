#!/bin/bash
# package_macos.sh — madcide's macOS tarball, standing alone:
#
#   madcide-<ver>-macos-<arch>.tar.gz   one folder, madcide-<ver>-macos-
#                                       <arch>/: the madc release it is paired
#                                       with (madc's tarball) and madcide in
#                                       it. Unpack it, run bin/madcide.
#
#   scripts/package_macos.sh [-o DIST]
#
#   MADC          as build.sh
#   MADC_PACKAGE  that madc's release tarball, which the tarball carries
#   -o DIST       where the tarball goes (default dist/), its line in its
#                 SHA256SUMS
#
# Run on a Mac of the architecture it packages: madcide is AOT-compiled by
# the madc there. The version is tools/madcide/madcide_version.h's; the
# tarball is checked to hold exactly the staged files.
set -eu
. "$(dirname "$0")/common.sh"
dist=$here/dist
while [ $# -gt 0 ]; do
	case "$1" in
	-o) dist=$2; shift 2 ;;
	*) echo "usage: $0 [-o DIST]" >&2; exit 2 ;;
	esac
done
if [ "$(uname -s)" != Darwin ]; then
	echo "package_macos.sh: run it on a Mac (madcide is AOT-compiled by the madc there)" >&2
	exit 1
fi
ver=$(sed -n 's/^#define MADCIDE_VERSION "\(.*\)"$/\1/p' "$here/tools/madcide/madcide_version.h")
[ -n "$ver" ] || { echo "package_macos.sh: no MADCIDE_VERSION in tools/madcide/madcide_version.h" >&2; exit 1; }
madc_paired || exit 1

work=$here/tmp/package-macos
rm -rf "$work"
mkdir -p "$work" "$dist"
dist=$(cd "$dist" && pwd)
bash "$here/scripts/build.sh" -o "$work/build"
folder=madcide-$ver-macos-$(uname -m)
madc_unpack "$madc_pkg" "$work/tar/$folder"
MADCIDE_BUILD="$work/build" bash "$here/scripts/stage.sh" macos "$work/tar/$folder"
plain_modes "$work/tar"
tgz=$folder.tar.gz
tar -C "$work/tar" -czf "$dist/$tgz" "$folder"
if ! diff <(tar -tzf "$dist/$tgz" | grep -v '/$' | LC_ALL=C sort) \
	  <(cd "$work/tar" && find . ! -type d | sed 's|^\./||' | LC_ALL=C sort) > "$work/diff"; then
	echo "package_macos.sh: $tgz does not hold exactly the staged files:" >&2
	cat "$work/diff" >&2
	exit 1
fi
refresh_sums "$dist" "$tgz"
echo "package_macos.sh: $dist/$tgz (madc $madc_ver)"
