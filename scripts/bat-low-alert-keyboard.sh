#!/bin/bash
pgrep -f "bat-low-alert-keyboard.sh" | grep -v $$ | xargs kill 2>/dev/null

KEYBOARD_MAC="C4:E6:90:31:4D:4F"

bat_low_level_alert() {
    bluetoothctl info "$KEYBOARD_MAC" 2>/dev/null | grep -q "Connected: yes" || return

    upower_out=$(upower -i /org/freedesktop/UPower/devices/keyboard_dev_C4_E6_90_31_4D_4F)
    echo "$upower_out" | grep -q "should be ignored" && return
    battery_level=$(echo "$upower_out" | grep percentage | awk '{gsub("%","",$2); print $2}')
    [ -z "$battery_level" ] && return

    if [ "$battery_level" -lt 30 ]; then
        env DISPLAY=:0 \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus \
            XDG_RUNTIME_DIR=/run/user/$(id -u) \
            dunstify "🚨 Keyboard battery Low 🚨" "Battery level is ${battery_level}%"
    fi
}

while true; do
    bat_low_level_alert
    sleep 60
done
