#!/usr/bin/env bash
set -euo pipefail

OUT_DIR=/tmp
BIN_PATH=/usr/local/bin
URL=https://telegram.org/dl/desktop/linux
FILE_NAME=telegram.tar.xz

echo "Downloading Telegram Desktop latest version to $(realpath $OUT_DIR)..."
if curl -L -# "$URL" -o "$OUT_DIR/$FILE_NAME"; then
    sudo kill $(ps aux | grep -i telegram | grep -v grep | grep -v "$0" | awk '{print $2}') 2>/dev/null || echo "Telegram is not running"
    sudo rm -r $BIN_PATH/Telegram
    sudo rm -r $BIN_PATH/Updater
    sudo tar -xf $OUT_DIR/$FILE_NAME -C $BIN_PATH --strip-components=1
    echo "Install complete, starting Telegram Desktop..."
    i3-msg 'workspace 10; exec Telegram'
    rm $OUT_DIR/$FILE_NAME
else
   echo "Download error"
   exit 1
fi