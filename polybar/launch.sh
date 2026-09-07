#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar on every enabled monitor. "connected" is not enough: an output
# can stay connected while switched off, and a bar on a switched-off output is
# invisible and only wastes a process. The systray goes on the primary monitor
# only — a second bar claiming it would just lose the race and log an error.
if type "xrandr"; then
    primary=$(xrandr -q | awk '$2 == "connected" && $3 == "primary" { print $1; exit }')
    for m in $(xrandr --listactivemonitors | awk 'NR > 1 { print $NF }'); do
        if [ "$m" = "$primary" ]; then
            tray=right
        else
            tray=none
        fi
        MONITOR=$m TRAY_POSITION=$tray polybar --reload main 2>&1 | tee -a /tmp/polybar.log &
    done
else
    TRAY_POSITION=right polybar --reload main 2>&1 | tee -a /tmp/polybar.log &
fi
