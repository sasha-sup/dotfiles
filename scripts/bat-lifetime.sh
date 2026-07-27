#!/bin/bash
# Kill previous instances only. A real instance has the script path as argv[1],
# so callers that merely mention the name in their command line are left alone.
for pid in $(pgrep -f 'bat-lifetime\.sh'); do
    [[ "$pid" == "$$" ]] && continue
    argv1=$(tr '\0' '\n' < "/proc/$pid/cmdline" 2>/dev/null | sed -n '2p')
    [[ "$argv1" == *bat-lifetime.sh ]] && kill "$pid" 2>/dev/null
done

bat_output_file=/tmp/bat_status

get_battery_info() {
    upower_output=$(upower -i /org/freedesktop/UPower/devices/DisplayDevice)
    percentage=$(echo "$upower_output" | grep -E 'percentage' | awk '{gsub(/[^0-9.]/, "", $2); print int($2)}')
    state=$(echo "$upower_output" | grep -E 'state' | awk '{print $2}')
    time_to_full=$(echo "$upower_output" | grep -E 'time to full' | sed 's/,/./' | awk '{print $4" "$5}')
    time_to_empty=$(echo "$upower_output" | grep -E 'time to empty' | sed 's/,/./' | awk '{print $4" "$5}')
}

# upower reports "4.2 hours" / "35.0 minutes" -> normalise to H:MM
format_time() {
    local value unit total_minutes
    value=$(echo "$1" | awk '{print $1}')
    unit=$(echo "$1" | awk '{print $2}')
    [[ -z "$value" || -z "$unit" ]] && return 1
    case "$unit" in
        hour|hours)     total_minutes=$(awk -v v="$value" 'BEGIN{printf "%d", v * 60}') ;;
        minute|minutes) total_minutes=$(awk -v v="$value" 'BEGIN{printf "%d", v}') ;;
        second|seconds) total_minutes=$(awk -v v="$value" 'BEGIN{printf "%d", v / 60}') ;;
        *) return 1 ;;
    esac
    [[ "$total_minutes" -le 0 ]] && return 1
    printf '%d:%02d' "$((total_minutes / 60))" "$((total_minutes % 60))"
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
        output="${bat_status_display} ${percentage}%"
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
        output="${bat_status_display} ${percentage}%"
        if formatted_time_to_empty=$(format_time "$time_to_empty"); then
            output="${output} 󰔟 ${formatted_time_to_empty}"
        fi
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
