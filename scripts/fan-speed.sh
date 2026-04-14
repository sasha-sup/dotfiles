#!/bin/bash
pgrep -f "fan-speed.sh" | grep -v $$ | xargs kill 2>/dev/null

get_fan_speed() {
    fan_path=$(find /sys/devices/platform/thinkpad_hwmon/hwmon/ -name 'fan1_input' 2>/dev/null)
    if [ -n "$fan_path" ]; then
        cat "$fan_path"
    else
        echo "Error: can't find fan device"
    fi
}

output_file="/tmp/fan_speed"

while true; do
    fan_speed=$(get_fan_speed)
    echo "$fan_speed" > "$output_file"
    sleep 5
done
