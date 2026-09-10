#!/bin/bash
set -euo pipefail

# i3 runs this from exec_always, so a restart can overlap with a still-running
# copy. Hold the lock on an explicit fd instead of "flock <file> <command>":
# that form leaks its fd into every child, and the polybar we start below is a
# long-lived one, so it kept holding the lock and starved every later run.
lock="${XDG_RUNTIME_DIR:-/tmp}/hdmi-output.lock"
exec 9>"$lock"
if ! flock -w 10 9; then
    echo "Another hdmi-output.sh run holds ${lock}" >&2
    exit 1
fi

# polybar binds to one monitor name at launch and no longer reloads itself on
# RandR changes, so whoever moves the outputs owns putting the bar back. Close
# fd 9 for it so the bar never inherits the lock.
launch_bar() {
    bar="$HOME/.config/polybar/launch.sh"
    [ -x "$bar" ] || return 0
    "$bar" >/dev/null 2>&1 9>&- &
}

panel="eDP-1"
query=$(xrandr -q)

if ! printf '%s\n' "$query" | grep -q "^${panel} "; then
    echo "Laptop panel ${panel} is unknown to xrandr" >&2
    exit 1
fi

# The laptop panel is the main screen: it is the primary output and takes the
# orphaned workspaces. The external monitor is the second screen and keeps the
# top of the stack at 0x0, with the panel directly below it, because that is
# where it physically stands. Primary and 0x0 are separate things here.
external=$(printf '%s\n' "$query" | awk -v panel="$panel" '$2 == "connected" && $1 != panel { print $1; exit }')
target="$panel"

# Geometry of one output as xrandr reports it ("1920x1080+0+2160"), empty when
# the output is off. The mode sits at field 3 or 4 depending on "primary".
geometry() {
    printf '%s\n' "$query" |
        awk -v out="$1" '$1 == out { for (i = 3; i <= NF; i++) if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) { print $i; exit } }'
}

# Bail out when the layout already matches. Applying the same mode again blanks
# and flashes the screen, and the workspace sweep below visibly cycles through
# every workspace. Both are noticeable at login, where this script runs twice:
# once from i3 exec_always, then again from the autorandr postswitch hook that
# 40-monitor-hotplug.rules triggers on the DRM change the first run caused.
enabled=$(printf '%s\n' "$query" |
    awk '/^[^ ]+ (connected|disconnected)/ && /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/ { print $1 }' | sort)
primary=$(printf '%s\n' "$query" | awk '$2 == "connected" && $3 == "primary" { print $1 }')

if [ -n "$external" ]; then
    want_enabled=$(printf '%s\n%s\n' "$external" "$panel" | sort)
    external_geometry=$(geometry "$external")
    panel_geometry=$(geometry "$panel")
    external_height=${external_geometry#*x}
    external_height=${external_height%%+*}
    if [ "$enabled" = "$want_enabled" ] && [ "$primary" = "$panel" ] &&
        [ "${external_geometry#*+}" = "0+0" ] &&
        [ "${panel_geometry#*+}" = "0+${external_height}" ]; then
        echo "${panel} is already primary with ${external} above it; nothing to do"
        # Waking from the lock screen leaves the layout untouched but can still
        # have taken the bar down with it, so revive it without restarting a
        # live one.
        pgrep -u "$UID" -x polybar >/dev/null || launch_bar
        exit 0
    fi
elif [ "$enabled" = "$panel" ] && [ "$primary" = "$panel" ]; then
    echo "${panel} is already the only active output; nothing to do"
    pgrep -u "$UID" -x polybar >/dev/null || launch_bar
    exit 0
fi

# A single xrandr call places the outputs we keep and switches every other one
# off, including disconnected ones that xrandr still keeps active with a stale
# mode. Leaving those on makes i3 keep workspaces bound to invisible outputs.
if [ -n "$external" ]; then
    # The external monitor holds 0x0 and --below anchors the panel to its left
    # edge, one full external height down, so the desktop is a single vertical
    # stack. --primary rides on the panel, not on whoever sits at the origin.
    args=(--output "$external" --auto --pos 0x0
        --output "$panel" --auto --primary --below "$external")
else
    args=(--output "$panel" --auto --primary --pos 0x0)
fi
while read -r name; do
    [ "$name" = "$panel" ] && continue
    if [ -n "$external" ] && [ "$name" = "$external" ]; then
        continue
    fi
    args+=(--output "$name" --off)
done < <(printf '%s\n' "$query" | awk '/^[^ ]+ (connected|disconnected)/ { print $1 }')

xrandr "${args[@]}"

if [ -n "$external" ]; then
    echo "${panel} is primary; external monitor ${external} sits above it"
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
