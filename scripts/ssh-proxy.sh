#!/bin/bash
. "${DOTFILES_ENV:-$HOME/.config/dotfiles.env}" 2>/dev/null || true

SOCKS_PORT="${SSH_PROXY_SOCKS_PORT:-1080}"
SSH_PORT="${SSH_PROXY_PORT:?SSH_PROXY_PORT not set (see ~/.config/dotfiles.env)}"
SSH_HOST="${SSH_PROXY_HOST:?SSH_PROXY_HOST not set (see ~/.config/dotfiles.env)}"
CONTROL_SOCKET="/tmp/ssh-proxy-${SOCKS_PORT}.sock"

if ssh -S "$CONTROL_SOCKET" -O check -p "$SSH_PORT" "$SSH_HOST" >/dev/null 2>&1; then
    echo "SSH proxy is running. Shutting it down..."
    if ssh -S "$CONTROL_SOCKET" -O exit -p "$SSH_PORT" "$SSH_HOST"; then
        echo "SSH proxy is off."
        exit 0
    fi

    echo "Failed to stop SSH proxy."
    exit 1
fi

if [ -S "$CONTROL_SOCKET" ]; then
    rm -f "$CONTROL_SOCKET"
fi

echo "Starting SSH proxy on SOCKS port $SOCKS_PORT..."

if ssh -f -N -M \
-S "$CONTROL_SOCKET" \
-D "$SOCKS_PORT" \
-p "$SSH_PORT" \
-o ServerAliveInterval=60 \
-o ServerAliveCountMax=3 \
-o ExitOnForwardFailure=yes \
"$SSH_HOST"; then
    echo "SSH proxy is on."
    exit 0
fi

echo "Failed to start SSH proxy."
exit 1
