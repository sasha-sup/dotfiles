#!/usr/bin/env bash
set -euo pipefail

# Installs / updates Ledger Live Desktop AppImage into ~/.local/bin/ledger.
#
# ~/.local/bin is used on purpose: the app's built-in electron-updater replaces
# the AppImage in place, which needs write access to the *directory*. In
# /usr/local/bin (root-owned) that fails with EACCES on unlink.

FEED_URL=https://download.live.ledger.com/latest-linux.yml
BASE_URL=https://download.live.ledger.com
BIN_PATH="$HOME/.local/bin/ledger"

FEED=$(curl -fsSL --max-time 30 "$FEED_URL")
VERSION=$(printf '%s\n' "$FEED" | sed -n 's/^version: *//p')
FILE_NAME=$(printf '%s\n' "$FEED" | sed -n 's/^path: *//p')
SHA512=$(printf '%s\n' "$FEED" | sed -n '/^path:/,$ s/^sha512: *//p' | head -1)

if [ -z "$VERSION" ] || [ -z "$FILE_NAME" ] || [ -z "$SHA512" ]; then
    echo "ERROR: could not parse $FEED_URL"
    exit 1
fi

echo "Latest Ledger Live Desktop: $VERSION"

if [ -x "$BIN_PATH" ] && \
   [ "$(openssl dgst -sha512 -binary "$BIN_PATH" | base64 -w0)" = "$SHA512" ]; then
    echo "Already up to date: $BIN_PATH"
    exit 0
fi

TMP_FILE=$(mktemp -t ledger-live-XXXXXX.AppImage)
trap 'rm -f "$TMP_FILE"' EXIT

echo "Downloading $FILE_NAME..."
curl -fL -# --max-time 1800 "$BASE_URL/$FILE_NAME" -o "$TMP_FILE"

GOT=$(openssl dgst -sha512 -binary "$TMP_FILE" | base64 -w0)
if [ "$GOT" != "$SHA512" ]; then
    echo "ERROR: sha512 mismatch"
    echo "  expected: $SHA512"
    echo "  got:      $GOT"
    exit 1
fi
echo "sha512 OK"

mkdir -p "$(dirname "$BIN_PATH")"
install -m 755 "$TMP_FILE" "$BIN_PATH"
echo "Installed $VERSION to $BIN_PATH"

# The old AppImage may still be in root-owned /usr/local/bin and shadow this one
# if that directory comes first in PATH.
if [ -e /usr/local/bin/ledger ]; then
    echo "WARNING: /usr/local/bin/ledger still exists and may shadow $BIN_PATH."
    echo "         Remove it: sudo rm /usr/local/bin/ledger"
fi
