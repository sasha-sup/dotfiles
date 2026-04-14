#!/bin/bash
pgrep -f "bat-low-alert-mouse.sh" | grep -v $$ | xargs kill 2>/dev/null

bat_low_level_alert() {
    battery_level=$(upower -i /org/freedesktop/UPower/devices/mouse_dev_C8_47_DE_0E_4C_1D | grep percentage | awk '{gsub("%","",$2); print $2}')
    
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