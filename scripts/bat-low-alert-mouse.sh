#!/bin/bash
pgrep -f "bat-low-alert-mouse.sh" | grep -v $$ | xargs kill 2>/dev/null

MOUSE_MAC="C8:47:DE:0E:4C:1D"

bat_low_level_alert() {
    bluetoothctl info "$MOUSE_MAC" 2>/dev/null | grep -q "Connected: yes" || return

    upower_out=$(upower -i /org/freedesktop/UPower/devices/mouse_dev_C8_47_DE_0E_4C_1D)
    echo "$upower_out" | grep -q "should be ignored" && return
    battery_level=$(echo "$upower_out" | grep percentage | awk '{gsub("%","",$2); print $2}')
    [ -z "$battery_level" ] && return

    if [ "$battery_level" -lt 30 ]; then
        env DISPLAY=:0 \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus \
            XDG_RUNTIME_DIR=/run/user/$(id -u) \
            dunstify "🚨 Mouse battery Low 🚨" "Battery level is ${battery_level}%"
    fi
}

while true; do
    bat_low_level_alert
    sleep 60
done