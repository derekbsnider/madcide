#!/bin/bash
# package_linux.sh — madcide's Linux packages, each standing alone: each
# carries the madc release it is paired with, so one package is the whole
# install.
#
#   madcide_<ver>-<rel>_<arch>.deb       install madcide and its madc in
#   madcide-<ver>-<rel>.<arch>.rpm       /usr/lib/madcide/ (madc's folder
#                                        layout), with /usr/bin/madcide, its
#                                        man page and its copyright under
#                                        /usr; no madc package needed, none
#                                        disturbed
#   madcide-<ver>-linux-<arch>.tar.gz    one folder, madcide-<ver>-linux-
#                                        <arch>/: madc's tarball with madcide
#                                        in it. Unpack it, run bin/madcide.
#
#   scripts/package_linux.sh [--deb] [-o DIST]
#
#   MADC             as build.sh
#   MADCIDE_BUILD    what scripts/build.sh -o DIR already built, packaged
#                    as it is (default: built now; scripts/common.sh's
#                    package_build)
#   MADC_PACKAGE    that madc's release package, which the packages carry:
#                    its tarball, or for --deb the .deb of this Ubuntu release
#   PKG_RELEASE      the package revision (default 1)
#   --deb            the .deb alone (another Ubuntu release's)
#   -o DIST          where the packages go (default dist/), their lines in
#                    its SHA256SUMS
#
# The version is tools/madcide/madcide_version.h's. madcide imports madc's
# ui_web module for its window (--gui), and an imported module opens at
# program start, so the WebKitGTK 6.0 and GTK 4 libraries that module binds
# are required, in every face. Each package is checked to hold exactly the
# staged files, each readable by every user.
#
# One .deb per Ubuntu release, built on it with that release's madc: on
# Ubuntu the revision is <rel>~ubuntu<VERSION_ID>, as madc's is, and the
# Depends is what the binaries link at this host's versions
# (dpkg-shlibdeps), so a package built for a newer release never installs
# on an older one.
set -eu
. "$(dirname "$0")/common.sh"
dist=$here/dist
deb_only=0
while [ $# -gt 0 ]; do
	case "$1" in
	--deb) deb_only=1; shift ;;
	-o) dist=$2; shift 2 ;;
	*) echo "usage: $0 [--deb] [-o DIST]" >&2; exit 2 ;;
	esac
done
version_h=$here/tools/madcide/madcide_version.h
ver=$(sed -n 's/^#define MADCIDE_VERSION "\(.*\)"$/\1/p' "$version_h")
home=$(sed -n 's/^#define MADCIDE_HOME_PAGE "\(.*\)"$/\1/p' "$version_h")
rel=${PKG_RELEASE:-1}
debrel=$rel
apparmor=0
if [ "$( (. /etc/os-release 2>/dev/null; echo "${ID:-}") )" = ubuntu ]; then
	osver=$( (. /etc/os-release; echo "$VERSION_ID") )
	debrel="$rel~ubuntu$osver"
	# Ubuntu 24.04 and later deny an unprofiled program the user
	# namespaces the window's WebKit sandbox (bwrap) needs, and the
	# window dies at its first page (LP: #2046844). There the .deb
	# carries an AppArmor profile naming its programs.
	if dpkg --compare-versions "$osver" ge 24.04; then
		apparmor=1
	fi
fi
if [ -z "$ver" ]; then
	echo "package_linux.sh: no MADCIDE_VERSION in $version_h" >&2
	exit 1
fi
madc_paired || exit 1
case "$(uname -m)" in
x86_64) deb_arch=amd64; rpm_arch=x86_64 ;;
aarch64) deb_arch=arm64; rpm_arch=aarch64 ;;
*) echo "package_linux.sh: no package architecture for $(uname -m)" >&2; exit 1 ;;
esac
maint="Derek Snider <coding@psychedeliccanada.ca>"
summary="The madc IDE: an editor, a REPL and a window over madc's engine"
desc="madcide is an editor for C, C++ and madc in a terminal or a window,
with madc's compiler inside it: the REPL beside the editor, problems as
you type, run and stop, key styles (VS Code, Vim, Emacs, JOE, Pico) and
plugins. It carries the madc release it runs on."

work=$here/tmp/package-linux
rm -rf "$work"
mkdir -p "$work" "$dist"
dist=$(cd "$dist" && pwd)
package_build "$work" || exit 1
strip --strip-unneeded "$work/build/madcide" "$work/build/$baselib"
# stage ROOT — the paired madc's folder with madcide in it.
stage() {
	madc_unpack "$madc_pkg" "$1"
	MADCIDE_BUILD="$work/build" bash "$here/scripts/stage.sh" linux "$1"
}
# stage_system USR — a package's usr/: the folder in lib/madcide/, and what
# the system reads in its own places — the program on PATH, its man page,
# madcide's copyright.
stage_system() {
	local usr=$1 priv=$1/lib/madcide
	stage "$priv"
	mkdir -p "$usr/bin" "$usr/share/doc" "$usr/share/man/man1"
	ln -s ../lib/madcide/bin/madcide "$usr/bin/madcide"
	mv "$priv/share/man/man1/madcide.1.gz" "$usr/share/man/man1/"
	mv "$priv/share/doc/madcide" "$usr/share/doc/"
}
# The staged entries of PREFIX (files and links), one path per line,
# relative to it.
staged() {
	(cd "$1" && find . ! -type d | sed 's|^\./||' | LC_ALL=C sort)
}
# check NAME LISTING STAGE — the package holds exactly the staged files.
check() {
	if ! diff <(LC_ALL=C sort <<< "$2") <(staged "$3") > "$work/diff"; then
		echo "package_linux.sh: $1 does not hold exactly the staged files:" >&2
		cat "$work/diff" >&2
		exit 1
	fi
}
# check_modes NAME LONG-LISTING — every entry is a 0755 directory or
# executable, a 0644 file (readable by every user), or a link.
check_modes() {
	local bad
	bad=$(awk '$1 !~ /^(drwxr-xr-x|-rwxr-xr-x|-rw-r--r--|lrwxrwxrwx)$/' <<< "$2")
	if [ -n "$bad" ]; then
		echo "package_linux.sh: $1 installs entries with other modes:" >&2
		echo "$bad" >&2
		exit 1
	fi
}

# ---- deb ----
debroot=$work/deb
stage_system "$debroot/usr"
mkdir -p "$debroot/DEBIAN"
# What every program and library the package carries links, at this host's
# versions; the carried libraries (libmadc, libmadcide, ...) resolve among
# themselves (-l). The ui_web module's WebKitGTK and GTK are among them.
priv=$debroot/usr/lib/madcide
elves=()
while IFS= read -r f; do
	[ "$(head -c 4 "$f" | od -An -c | tr -d ' ')" = '177ELF' ] && elves+=("$f")
done < <(find "$priv" -type f)
mkdir -p "$work/shlibdeps/debian"
printf 'Source: madcide\n\nPackage: madcide\nArchitecture: any\n' > "$work/shlibdeps/debian/control"
shlibs=$(cd "$work/shlibdeps" && dpkg-shlibdeps -O --ignore-missing-info \
		-l"$priv/lib" "${elves[@]}" 2> shlibdeps.log |
	sed -n 's/^shlibs:Depends=//p')
if [ -z "$shlibs" ]; then
	echo "package_linux.sh: dpkg-shlibdeps named no dependencies (see $work/shlibdeps/shlibdeps.log)" >&2
	exit 1
fi
cat > "$debroot/DEBIAN/control" << EOC
Package: madcide
Version: $ver-$debrel
Section: devel
Priority: optional
Architecture: $deb_arch
Maintainer: $maint
Depends: $shlibs
Homepage: $home
Description: $summary
$(printf '%s\n' "$desc" | sed 's/^/ /')
EOC
if [ "$apparmor" = 1 ]; then
	# The shape of Ubuntu's own profiles for its WebKit programs
	# (epiphany, devhelp): unconfined, with user namespaces. postinst
	# loads it as dh_apparmor's snippet does. Two programs open windows:
	# madcide, and the madc it carries (a ui:: program it runs).
	mkdir -p "$debroot/etc/apparmor.d"
	cat > "$debroot/etc/apparmor.d/madcide" << 'EOC'
# madcide's window is WebKitGTK, whose sandbox (bwrap) needs user
# namespaces, and so is the window of a ui:: program the madc it carries
# runs. These profiles allow everything else, as before; they only name
# the programs so AppArmor grants them.

abi <abi/4.0>,
include <tunables/global>

profile madcide /usr/lib/madcide/bin/madcide flags=(unconfined) {
  userns,

  # Site-specific additions and overrides. See local/README for details.
  include if exists <local/madcide>
}

profile madcide-madc /usr/lib/madcide/bin/madc flags=(unconfined) {
  userns,

  include if exists <local/madcide-madc>
}
EOC
	echo /etc/apparmor.d/madcide > "$debroot/DEBIAN/conffiles"
	cat > "$debroot/DEBIAN/postinst" << 'EOC'
#!/bin/sh
set -e
if [ "$1" = configure ] && aa-enabled --quiet 2>/dev/null; then
	apparmor_parser -r -T -W /etc/apparmor.d/madcide || true
fi
EOC
	chmod 0755 "$debroot/DEBIAN/postinst"
fi
plain_modes "$debroot"
deb=madcide_$ver-${debrel}_$deb_arch.deb
dpkg-deb --build --root-owner-group "$debroot" "$dist/$deb" > /dev/null
check "$deb" "$(dpkg-deb -c "$dist/$deb" | awk '$1 !~ /^d/ { print $6 }' | sed -n 's|^\./usr/||p')" "$debroot/usr"
check_modes "$deb" "$(dpkg-deb -c "$dist/$deb")"
etc=$(dpkg-deb -c "$dist/$deb" | awk '$1 !~ /^d/ { print $6 }' | grep -v '^\./usr/' || true)
want=
[ "$apparmor" = 1 ] && want=./etc/apparmor.d/madcide
if [ "$etc" != "$want" ]; then
	echo "package_linux.sh: $deb installs '$etc' outside /usr, not '$want'" >&2
	exit 1
fi
if [ "$deb_only" = 1 ]; then
	refresh_sums "$dist" "$deb"
	echo "package_linux.sh: $dist/$deb (madc $madc_ver)"
	exit 0
fi

# ---- rpm ----
rpmtop=$work/rpm
mkdir -p "$rpmtop/BUILD" "$rpmtop/RPMS" "$rpmtop/SPECS" "$rpmtop/SOURCES"
buildroot=$rpmtop/BUILDROOT/madcide-$ver-$rel.$rpm_arch
stage_system "$buildroot/usr"
plain_modes "$buildroot"
cat > "$rpmtop/SPECS/madcide.spec" << EOC
Name: madcide
Version: $ver
Release: $rel
Summary: $summary
License: MPL-2.0
URL: $home
AutoReq: yes
AutoProv: no
# The carried libraries resolve among themselves; the ui_web module's
# DT_NEEDED (webkitgtk, gtk4) are Requires, as every other carried binary's.
%global __requires_exclude ^lib(madc|madcide)[-.]
%define debug_package %{nil}
%define __strip /bin/true
%define _build_id_links none

%description
$desc

%files
/usr/bin/madcide
/usr/lib/madcide
/usr/share/man/man1/madcide.1.gz
/usr/share/doc/madcide
EOC
rpmbuild --define "_topdir $rpmtop" --buildroot "$buildroot" -bb "$rpmtop/SPECS/madcide.spec" > "$work/rpmbuild.log" 2>&1 \
	|| { tail -20 "$work/rpmbuild.log" >&2; exit 1; }
rpm=madcide-$ver-$rel.$rpm_arch.rpm
cp "$rpmtop/RPMS/$rpm_arch/$rpm" "$dist/"
# rpmbuild removes its build root; the deb's is the same staging.
check "$rpm" "$(rpm -qlvp "$dist/$rpm" | awk '$1 !~ /^d/ { print ($(NF-1) == "->") ? $(NF-2) : $NF }' | sed 's|^/usr/||')" "$debroot/usr"
check_modes "$rpm" "$(rpm -qlvp "$dist/$rpm")"

# ---- tarball: one folder, madc's tarball with madcide in it ----
tarstage=$work/tar
folder=madcide-$ver-linux-$rpm_arch
stage "$tarstage/$folder"
plain_modes "$tarstage"
tgz=$folder.tar.gz
tar -C "$tarstage" --owner=0 --group=0 -czf "$dist/$tgz" "$folder"
check "$tgz" "$(tar -tzf "$dist/$tgz" | grep -v '/$')" "$tarstage"
check_modes "$tgz" "$(tar -tzvf "$dist/$tgz")"

refresh_sums "$dist" "$deb" "$rpm" "$tgz"
echo "package_linux.sh: $dist/{$deb,$rpm,$tgz} (madc $madc_ver)"
