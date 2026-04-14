#!/bin/bash
pgrep -f "bat-lifetime.sh" | grep -v $$ | xargs kill 2>/dev/null

bat_output_file=/tmp/bat_status

get_battery_info() {
    upower_output=$(upower -i /org/freedesktop/UPower/devices/DisplayDevice)
    percentage=$(echo "$upower_output" | grep -E 'percentage' | awk '{gsub(/[^0-9.]/, "", $2); print int($2)}')
    state=$(echo "$upower_output" | grep -E 'state' | awk '{print $2}')
    time_to_full=$(echo "$upower_output" | grep -E 'time to full' | awk '{print $4}' | sed 's/,//g')
    time_to_empty=$(echo "$upower_output" | grep -E 'time to empty' | awk '{print $4}' | sed 's/,//g')
}

format_time() {
    local raw_time=$1
    if [[ -n "$raw_time" ]]; then
        hours=$(echo "$raw_time" | awk -F: '{print int($1)}')
        minutes=$(echo "$raw_time" | awk -F: '{print int($2)}')
        echo "${hours}:${minutes}"
    else
        echo "N/A"
    fi
}

print_battery_status() {
    if [[ -z "$percentage" ]]; then
        echo "Error" > "$bat_output_file"
        return
    fi
    if [[ "$state" == "fully-charged" ]]; then
        bat_status_display="󰁹"
        output="${bat_status_display} FULL"
    elif [[ "$state" == "charging" ]]; then
        bat_status_display="󰂄"
        formatted_time_to_full=$(format_time "$time_to_full")
        output="${bat_status_display} ${percentage}% 󰔟 ${formatted_time_to_full}"
    elif [[ "$state" == "discharging" ]]; then
        if [[ "$percentage" -ge 80 ]]; then
            bat_status_display="󰂁"
        elif [[ "$percentage" -ge 60 ]]; then
            bat_status_display="󰁿"
        elif [[ "$percentage" -ge 40 ]]; then
            bat_status_display="󰁽"
        elif [[ "$percentage" -ge 20 ]]; then
            bat_status_display="󰁻"
        else
            bat_status_display="󰁺"
        fi
        formatted_time_to_empty=$(format_time "$time_to_empty")
        output="${bat_status_display} ${percentage}% 󰔟 ${formatted_time_to_empty}"
    else
        bat_status_display="󰂎"
        output="${bat_status_display} ${percentage}%"
    fi
    echo "$output" > "$bat_output_file"
}

while true; do
    get_battery_info
    print_battery_status
    sleep 5
done
