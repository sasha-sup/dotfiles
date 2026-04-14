#!/bin/bash
pgrep -f "bat-low-alert-keyboard.sh" | grep -v $$ | xargs kill 2>/dev/null

bat_low_level_alert() {
    battery_level=$(upower -i /org/freedesktop/UPower/devices/keyboard_dev_C4_E6_90_31_4D_4F | grep percentage | awk '{gsub("%","",$2); print $2}')
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
