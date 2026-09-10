#!/usr/bin/env bash
set -euo pipefail

# Builds i3lock-color and installs it as /usr/local/bin/i3lock-color.
#
# Debian does not package it — trixie ships plain i3lock 2.15, which draws a
# fixed white ring and nothing else. scripts/lock.sh wants a clock, a keyboard
# layout readout and the polybar palette, and only this fork has them.
#
# The binary is deliberately NOT named i3lock and NOT installed into /usr/bin:
# the packaged /usr/bin/i3lock stays untouched, so a broken build here degrades
# to a plain lock screen instead of no lock screen at all. lock.sh falls back to
# it on its own. The PAM service name compiled into the fork is still "i3lock",
# which is why /etc/pam.d/i3lock from the Debian package has to stay installed.

REPO_URL=https://github.com/Raymo111/i3lock-color.git
SRC_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/i3lock-color"
BIN_PATH=/usr/local/bin/i3lock-color

# Pinned to a release tag, not HEAD: this binary authenticates against PAM and
# holds the screen, so what gets built has to be the same thing every time. The
# commit is pinned too — a tag is a mutable pointer upstream, and checking the
# sha turns a retagged release into a hard failure instead of a silent swap.
#
# 2.13.c.5 is an annotated tag, so it has two shas: the tag object is
# a601df351727b0e0a69532aabda849b11ef05e7a and the commit it points at is the
# one below. git rev-parse HEAD after checkout yields the commit, so that is
# what the check compares — "git ls-remote --refs" prints the tag object and
# would not match. Peel it with "git ls-remote <url> 'refs/tags/<tag>^{}'".
REF=2.13.c.5
REF_COMMIT=7b2badbb407ef5fce1eb338a98974ad5f70e226e

# gif and jpeg headers are not pulled in by i3lock's own build-dep set, and
# configure fails on them late, after everything else has already been checked.
BUILD_DEPS=(
    autoconf automake pkg-config
    libpam0g-dev libcairo2-dev libfontconfig1-dev libev-dev
    libgif-dev libjpeg-dev
    libx11-dev libx11-xcb-dev
    libxcb-composite0-dev libxcb-image0-dev libxcb-randr0-dev
    libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev libxcb-xrm-dev
    libxkbcommon-dev libxkbcommon-x11-dev
)

# The build stamps its version from git describe, so a tagged build prints the
# tag itself ("version 2.13.c.5 (2023-07-28)") while an untagged one prints a
# short sha. Matching on the tag is therefore enough to skip a rebuild.
if [ -x "$BIN_PATH" ] && "$BIN_PATH" --version 2>&1 | grep -q "version $REF "; then
    echo "Already at $REF: $BIN_PATH"
    exit 0
fi

missing=()
for pkg in "${BUILD_DEPS[@]}"; do
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed" || missing+=("$pkg")
done
if [ "${#missing[@]}" -gt 0 ]; then
    echo "Installing build dependencies: ${missing[*]}"
    sudo apt-get install -y --no-install-recommends "${missing[@]}"
fi

if [ ! -d "$SRC_DIR/.git" ]; then
    rm -rf "$SRC_DIR"
    git clone --depth 1 --branch "$REF" "$REPO_URL" "$SRC_DIR"
else
    git -C "$SRC_DIR" fetch --depth 1 origin "refs/tags/$REF:refs/tags/$REF" --force
    git -C "$SRC_DIR" checkout --detach --force "refs/tags/$REF"
fi

got=$(git -C "$SRC_DIR" rev-parse HEAD)
if [ "$got" != "$REF_COMMIT" ]; then
    echo "ERROR: tag $REF resolves to $got, expected $REF_COMMIT" >&2
    echo "Upstream moved the tag. Verify the change before bumping REF_COMMIT." >&2
    exit 1
fi

# Out-of-tree build. Running ./configure from the source root makes the wrapper
# Makefile recurse into a per-arch directory and then fail on all-configured.
cd "$SRC_DIR"
autoreconf -fi
rm -rf build
mkdir build
cd build
../configure --prefix=/usr/local --sysconfdir=/etc --disable-sanitizers
make -j"$(nproc)"

sudo install -m 0755 -o root -g root i3lock "$BIN_PATH"
echo "Installed $BIN_PATH: $("$BIN_PATH" --version 2>&1)"
