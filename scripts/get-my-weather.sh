#!/bin/bash
pgrep -f "get-my-weather.sh" | grep -v $$ | xargs kill 2>/dev/null

location="Moscow"
# Or use dynamic location based on ip.
# If you use a VPN, it will not work correctly!
# location=$(curl -s ipinfo.io | jq -r .'city')

output_format=2
# Formats:
# 1: 🌨  +0°C
# 2: 🌨  🌡️+0°C 🌬️→9km/h
# 3: Moscow: 🌨  +0°C
# 4: Moscow: 🌨  🌡️+0°C 🌬️→9km/h

get_weather=$(curl -s wttr.in/${location}?format=${output_format} | sed -E 's/[[:space:]]{2,}/ /g; s/^ //; s/ $//')
echo "󰍎 ${location}: $get_weather" > /tmp/get-my-weather.txt
