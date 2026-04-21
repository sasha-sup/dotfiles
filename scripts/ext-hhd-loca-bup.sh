#!/bin/bash

# Backup Script v2.0
# Full snapshot of $HOME to external drive

SOURCE_DIR="$HOME"
TARGET_DIR="/home/sasha/external-dick/pesos"
RSYNC_OPTS=(-rltvh --partial --progress --chown=sasha:sasha --omit-dir-times --delete)

EXCLUDES=(
    # Anything with "cache" in the name
    '*[Cc]ache*'

    # Trash and temp
    .local/share/Trash/
    .thumbnails/
    .Trash*/

    # Package manager stores
    .cargo/registry/
    .m2/repository/
    .nuget/

    # Runtime / state
    .local/share/Steam/
    .steam/
    snap/

    # Build artifacts and venvs
    node_modules/
    .venv/
    '*.pyc'
    .tox/
    target/

    # Git internals inside projects
    Code/**/.git/

    # IDE / editor state
    .vscode/
    .idea/

    # OMC state
    .omc/
    .omx/

    # Browser profiles
    .mozilla/
    .config/google-chrome/
    .config/chromium/
    .config/BraveSoftware/

    # External drive and Go SDK
    external-dick/
    go/

    # Music
    Music/

    # Large game files in Downloads
    Downloads/Factorio_Linux/
    Downloads/GTA3VC_Linux/
    Downloads/HOMM3/
)

echo "=== Starting Full HOME Backup ==="

mountpoint -q "$(dirname "$TARGET_DIR")" || { echo "Error: External drive not mounted"; exit 1; }
mkdir -p "$TARGET_DIR"

EXCLUDE_ARGS=()
for pattern in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS+=(--exclude="$pattern")
done

echo "[*] Syncing $SOURCE_DIR -> $TARGET_DIR ..."
sudo rsync "${RSYNC_OPTS[@]}" "${EXCLUDE_ARGS[@]}" "$SOURCE_DIR/" "$TARGET_DIR/" || {
    echo "Error: rsync failed"; exit 1
}

echo "[*] Backing up /etc..."
sudo rsync -avhzP --delete /etc "$TARGET_DIR/" || {
    echo "Error: Failed to sync /etc"; exit 1
}

echo "[*] Syncing disk..."
sync

echo "=== Backup Completed Successfully ==="
