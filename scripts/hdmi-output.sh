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

# polybar binds to one monitor name at launch and no longer reloads itself on
# RandR changes, so whoever moves the outputs owns putting the bar back.
launch_bar() {
    bar="$HOME/.config/polybar/launch.sh"
    [ -x "$bar" ] || return 0
    "$bar" >/dev/null 2>&1 &
}

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

# Bail out when the layout already matches. Applying the same mode again blanks
# and flashes the screen, and the workspace sweep below visibly cycles through
# every workspace. Both are noticeable at login, where this script runs twice:
# once from i3 exec_always, then again from the autorandr postswitch hook that
# 40-monitor-hotplug.rules triggers on the DRM change the first run caused.
enabled=$(printf '%s\n' "$query" |
    awk '/^[^ ]+ (connected|disconnected)/ && /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/ { print $1 }')
primary=$(printf '%s\n' "$query" | awk '$2 == "connected" && $3 == "primary" { print $1 }')
if [ "$enabled" = "$target" ] && [ "$primary" = "$target" ]; then
    echo "${target} is already the only active output; nothing to do"
    # Waking from the lock screen leaves the layout untouched but can still have
    # taken the bar down with it, so revive it without restarting a live one.
    pgrep -u "$UID" -x polybar >/dev/null || launch_bar
    exit 0
fi

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

# The target output changed, so the bar is either gone with the old one or
# sitting on a monitor that no longer exists. Relaunch it on the new layout.
launch_bar
