#!/usr/bin/env bash
set -euo pipefail

OUT_DIR=/tmp
BIN_PATH=/usr/local/bin
FILE_NAME=telegram.tar.xz

step() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

# telegram.org/dl/desktop/linux lags GitHub releases by days, so ask GitHub directly
URL=$(curl -fsSL https://api.github.com/repos/telegramdesktop/tdesktop/releases/latest \
    | grep -o 'https://[^"]*/td-setup-linux-x64-[^"]*\.tar\.xz' | head -n1) || true
if [ -z "$URL" ]; then
    fail "Could not find linux tarball in latest GitHub release; check https://github.com/telegramdesktop/tdesktop/releases"
fi

VERSION=$(basename "$URL" .tar.xz); VERSION=${VERSION##*-}

step "Downloading Telegram Desktop $VERSION"
if curl -fL -# "$URL" -o "$OUT_DIR/$FILE_NAME"; then
    # exact process name: a substring match also hits browser tabs with "telegram" in the URL
    pkill -x Telegram || true
    step "Installing to $BIN_PATH"
    sudo rm -r $BIN_PATH/Telegram
    sudo rm -r $BIN_PATH/Updater
    sudo tar -xf $OUT_DIR/$FILE_NAME -C $BIN_PATH --strip-components=1
    step "Starting Telegram on workspace 9"
    i3-msg -q 'workspace 9; exec Telegram'
    rm $OUT_DIR/$FILE_NAME
else
    fail "Download failed: $URL"
fi