#!/bin/bash
# stage.sh — madcide's installed files, staged into a root: the one staging
# every package uses (package_linux.sh's .deb, .rpm and tarball,
# package_windows.sh's zip, package_macos.sh's tarball).
#
#   scripts/stage.sh LAYOUT ROOT
#
#   LAYOUT  linux    a prefix: bin/madcide, its base library in lib/, its
#                    data under share/madcide (scripts/stage_madcide_data.sh),
#                    its man page, its licence under share/doc/madcide
#           macos    the same
#           windows  a madc folder: madcide.exe, madcide.dll and madcide's
#                    data beside the programs in bin\ (PE binding's adjacency,
#                    which madcide's data search follows), its licence at the
#                    top as LICENSE-madcide.txt
#   ROOT    where the layout goes: the top of madc's folder (a package's
#           madc, unpacked) — madcide's base library sits in madc's own
#           library directory, where a product's "libs" are found first
#
#   MADCIDE_BUILD  what scripts/build.sh built (default build/)
set -eu
. "$(dirname "$0")/common.sh"
if [ $# -ne 2 ]; then
	echo "usage: $0 linux|macos|windows ROOT" >&2
	exit 2
fi
layout=$1
mkdir -p "$2"
root=$(cd "$2" && pwd)
built=${MADCIDE_BUILD:-$here/build}
case "$layout" in
linux|macos) sfx= libdir=$root/lib data=$root/share/madcide ;;
windows) sfx=.exe libdir=$root/bin data=$root/bin ;;
*) echo "usage: $0 linux|macos|windows ROOT" >&2; exit 2 ;;
esac
for f in "$built/madcide$sfx" "$built/$baselib" "$built/plugins"; do
	if [ ! -e "$f" ]; then
		echo "stage.sh: no $f — scripts/build.sh first" >&2
		exit 1
	fi
done
mkdir -p "$root/bin" "$libdir"
install -m 755 "$built/madcide$sfx" "$root/bin/madcide$sfx"
install -m 755 "$built/$baselib" "$libdir/$baselib"
bash "$here/scripts/stage_madcide_data.sh" "$data" "$built/plugins"
if [ "$layout" = windows ]; then
	install -m 644 "$here/LICENSE" "$root/LICENSE-madcide.txt"
else
	mkdir -p "$root/share/man/man1" "$root/share/doc/madcide"
	gzip -9n < "$here/docs/man/madcide.1" > "$root/share/man/man1/madcide.1.gz"
	install -m 644 "$here/LICENSE" "$root/share/doc/madcide/copyright"
fi
