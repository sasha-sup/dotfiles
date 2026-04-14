#!/bin/bash
pgrep -f "bat-low-alert.sh" | grep -v $$ | xargs kill 2>/dev/null

bat_low_level_alert() {
    battery_level=$(cat /sys/class/power_supply/BAT0/capacity)
    
    if [ "$battery_level" -lt 30 ]; then
        dunstify "🚨 Battery Low 🚨" "Battery level is ${battery_level}%"
    fi
}

while true; do
    bat_low_level_alert
    sleep 60
done