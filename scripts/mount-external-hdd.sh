#!/bin/bash

set -euo pipefail
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

. "${DOTFILES_ENV:-$HOME/.config/dotfiles.env}" 2>/dev/null || true

LUKS_UUID="${EXT_HDD_LUKS_UUID:?EXT_HDD_LUKS_UUID not set (see ~/.config/dotfiles.env)}"
MAPPER_NAME="external_crypt"
MAPPED_DEVICE="/dev/mapper/${MAPPER_NAME}"
MOUNT_POINT="${EXT_HDD_MOUNT_POINT:-$HOME/external-hdd}"

install_package() {
    local package="$1"

    if ! command -v apt-get >/dev/null 2>&1; then
        echo "Error: required package '${package}' is missing and apt-get is not available." >&2
        exit 1
    fi

    echo "Installing missing package '${package}'..."
    if [ "${EUID}" -eq 0 ]; then
        apt-get install -y "$package"
    elif command -v sudo >/dev/null 2>&1; then
        sudo apt-get install -y "$package"
    else
        echo "Error: cannot install '${package}' automatically because 'sudo' is unavailable." >&2
        exit 1
    fi
}

ensure_cmd() {
    local cmd="$1"
    local package="$2"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        install_package "$package"
    fi

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: command '$cmd' is still unavailable after installing '${package}'." >&2
        exit 1
    fi
}

find_luks_device() {
    lsblk -rno PATH,UUID,FSTYPE | awk -v uuid="$LUKS_UUID" '$2 == uuid && $3 == "crypto_LUKS" { print $1; exit }'
}

ensure_cmd sudo sudo
ensure_cmd lsblk util-linux
ensure_cmd mountpoint util-linux
ensure_cmd cryptsetup cryptsetup
ensure_cmd mount util-linux
ensure_cmd umount util-linux

if mountpoint -q "$MOUNT_POINT"; then
    echo "Unmounting ${MOUNT_POINT}..."
    sudo umount "$MOUNT_POINT"

    if sudo cryptsetup status "$MAPPER_NAME" >/dev/null 2>&1; then
        echo "Closing LUKS mapping ${MAPPER_NAME}..."
        sudo cryptsetup close "$MAPPER_NAME"
    fi

    rmdir "$MOUNT_POINT" 2>/dev/null || true
    echo "Unmounted successfully."
    exit 0
fi

device=$(find_luks_device)

if [ -z "$device" ]; then
    echo "Error: LUKS device with UUID ${LUKS_UUID} not found." >&2
    exit 1
fi

opened_here=0
if ! sudo cryptsetup status "$MAPPER_NAME" >/dev/null 2>&1; then
    echo "Opening LUKS container ${device}..."
    sudo cryptsetup open "$device" "$MAPPER_NAME"
    opened_here=1
fi

mkdir -p "$MOUNT_POINT"

echo "Mounting ${MAPPED_DEVICE} to ${MOUNT_POINT}..."
if ! sudo mount "$MAPPED_DEVICE" "$MOUNT_POINT"; then
    if [ "$opened_here" -eq 1 ]; then
        sudo cryptsetup close "$MAPPER_NAME" || true
    fi
    echo "Error: failed to mount ${MAPPED_DEVICE}." >&2
    exit 1
fi

echo "Mounted successfully."
