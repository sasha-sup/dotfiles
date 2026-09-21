#!/usr/bin/env bash

# i3 starts this from exec_always, and hdmi-output.sh starts it too when it
# finds no bar. An i3 restart fires both at once: each run killed the old bars,
# saw none left and started its own set, so every monitor got two bars stacked
# on each other and their translucent backgrounds added up to an opaque one.
# Take turns instead, so a later run replaces the bars of an earlier one. The
# bars must not inherit the lock fd, or they would hold it for their lifetime.
# No timeout: a run that gave up would leave the bars of an older layout behind.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/polybar-launch.lock"
flock 9

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar on every enabled monitor. "connected" is not enough: an output
# can stay connected while switched off, and a bar on a switched-off output is
# invisible and only wastes a process. The systray goes on the primary monitor
# only — a second bar claiming it would just lose the race and log an error.
bars=0
if type "xrandr"; then
    primary=$(xrandr -q | awk '$2 == "connected" && $3 == "primary" { print $1; exit }')
    for m in $(xrandr --listactivemonitors | awk 'NR > 1 { print $NF }'); do
        if [ "$m" = "$primary" ]; then
            tray=right
        else
            tray=none
        fi
        MONITOR=$m TRAY_POSITION=$tray polybar --reload main 2>&1 9>&- | tee -a /tmp/polybar.log 9>&- &
        bars=$((bars + 1))
    done
else
    TRAY_POSITION=right polybar --reload main 2>&1 9>&- | tee -a /tmp/polybar.log 9>&- &
    bars=1
fi

# Keep the lock until the new bars exist. A run waiting on it would otherwise
# find nothing to kill yet and start a second set next to these.
for _ in $(seq 50); do
    [ "$(pgrep -cu "$UID" -x polybar)" -ge "$bars" ] && break
    sleep 0.1
done
