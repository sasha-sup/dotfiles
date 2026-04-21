#!/bin/bash
pgrep -f "hdmi-output.sh" | grep -v $$ | xargs kill 2>/dev/null

set -euo pipefail

primary="eDP-1"
output=$(xrandr -q)

if ! echo "$output" | grep -q "^${primary} connected"; then
    echo "Primary output ${primary} is not connected" >&2
    exit 1
fi

# Pick the first connected output that is not the laptop panel.
connected=$(printf '%s\n' "$output" | awk -v primary="$primary" '$2 == "connected" && $1 != primary { print $1; exit }')

# Turn off every disconnected output that xrandr still keeps enabled.
# (A disconnected output with a mode like "1920x1080+..." is still active and
# i3 keeps workspaces bound to it, which breaks workspace migration on restart.)
while read -r name rest; do
    [ "$name" = "$primary" ] && continue
    if echo "$rest" | grep -Eq '^disconnected [0-9]+x[0-9]+\+'; then
        xrandr --output "$name" --off || true
    fi
done < <(printf '%s\n' "$output" | awk '/^[^ ]+ (connected|disconnected)/{ $1=$1; name=$1; $1=""; sub(/^ /,""); print name, $0 }')

if [ -z "$connected" ]; then
    xrandr --output "$primary" --auto --primary
    echo "External monitor not found; only ${primary} is enabled"
else
    xrandr \
      --output "$primary" --auto --primary \
      --output "$connected" --auto --right-of "$primary"
fi

# Migrate workspaces that are still attached to outputs i3 no longer sees as active.
if command -v i3-msg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    active=$(i3-msg -t get_outputs | jq -r '.[] | select(.active) | .name')
    current=$(i3-msg -t get_workspaces | jq -r '.[] | .name')
    while read -r ws; do
        ws_out=$(i3-msg -t get_workspaces | jq -r --arg n "$ws" '.[] | select(.name==$n) | .output')
        if ! printf '%s\n' "$active" | grep -qx "$ws_out"; then
            i3-msg "workspace \"$ws\"; move workspace to output $primary" >/dev/null || true
        fi
    done <<< "$current"
fi
