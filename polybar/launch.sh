#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar on every enabled monitor. "connected" is not enough: the
# laptop panel stays connected while the lid is closed, and a bar on a
# switched-off output is invisible and only wastes a process.
if type "xrandr"; then
    for m in $(xrandr --listactivemonitors | awk 'NR > 1 { print $NF }'); do
        MONITOR=$m polybar --reload main 2>&1 | tee -a /tmp/polybar.log &
    done
else
    polybar --reload main 2>&1 | tee -a /tmp/polybar.log &
fi
