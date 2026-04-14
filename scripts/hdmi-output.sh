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

if [ -z "$connected" ]; then
    xrandr --output "$primary" --auto --primary
    echo "External monitor not found; only ${primary} is enabled"
    exit 0
fi

xrandr \
  --output "$primary" --auto --primary \
  --output "$connected" --auto --right-of "$primary"
