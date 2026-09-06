#!/bin/bash
set -euo pipefail

# i3 runs this from exec_always, so a restart can overlap with a still-running
# copy. Re-exec under flock instead of pkill: matching "hdmi-output.sh" by
# command line also kills shells that merely mention the script.
lock="${XDG_RUNTIME_DIR:-/tmp}/hdmi-output.lock"
if [ -z "${HDMI_OUTPUT_LOCKED:-}" ]; then
    export HDMI_OUTPUT_LOCKED=1
    exec flock -w 10 "$lock" "$0" "$@"
fi

panel="eDP-1"
query=$(xrandr -q)

if ! printf '%s\n' "$query" | grep -q "^${panel} "; then
    echo "Laptop panel ${panel} is unknown to xrandr" >&2
    exit 1
fi

# The external monitor is the only screen we want: the lid stays closed, so the
# laptop panel is switched off whenever anything else is plugged in. Falling
# back to the panel keeps the machine usable when nothing is connected.
external=$(printf '%s\n' "$query" | awk -v panel="$panel" '$2 == "connected" && $1 != panel { print $1; exit }')
target="${external:-$panel}"

# A single xrandr call enables the target and switches every other output off,
# including disconnected ones that xrandr still keeps active with a stale mode.
# Leaving those on makes i3 keep workspaces bound to invisible outputs.
args=(--output "$target" --auto --primary)
while read -r name; do
    [ "$name" = "$target" ] && continue
    args+=(--output "$name" --off)
done < <(printf '%s\n' "$query" | awk '/^[^ ]+ (connected|disconnected)/ { print $1 }')

xrandr "${args[@]}"

if [ -n "$external" ]; then
    echo "External monitor ${external} is the only active output"
else
    echo "External monitor not found; only ${panel} is enabled"
fi

# Migrate workspaces that are still attached to outputs i3 no longer sees as
# active, then return to whatever workspace was focused before the sweep.
if command -v i3-msg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    active=$(i3-msg -t get_outputs | jq -r '.[] | select(.active) | .name')
    focused=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')
    while IFS=$'\t' read -r ws ws_out; do
        printf '%s\n' "$active" | grep -qxF "$ws_out" && continue
        i3-msg "workspace \"$ws\"; move workspace to output $target" >/dev/null || true
    done < <(i3-msg -t get_workspaces | jq -r '.[] | "\(.name)\t\(.output)"')
    [ -n "$focused" ] && i3-msg "workspace \"$focused\"" >/dev/null || true
fi
