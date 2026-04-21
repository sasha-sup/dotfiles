#!/usr/bin/env bash
# Rofi-based WiFi picker for polybar network module.
# Left-click on the network module shows this menu.

set -u

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a "WiFi" "$1" "$2" || true
}

# Trigger a rescan so the list is fresh, then give NM a moment to update.
nmcli device wifi rescan >/dev/null 2>&1 || true
sleep 1

wifi_state=$(nmcli -t -f WIFI general 2>/dev/null | head -1)
if [[ "$wifi_state" == "enabled" ]]; then
    toggle_entry="󰖪  Disable WiFi"
else
    toggle_entry="󰖩  Enable WiFi"
fi

# SSID | SECURITY | SIGNAL — skip empty SSIDs and duplicates, keep strongest.
ssid_list=""
if [[ "$wifi_state" == "enabled" ]]; then
    ssid_list=$(nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL device wifi list 2>/dev/null \
        | awk -F: '
            $2 != "" && !seen[$2]++ {
                mark = ($1 == "*") ? "●" : " "
                sec  = ($3 == "")  ? "open" : $3
                printf "%s  %s  [%s] %s%%\n", mark, $2, sec, $4
            }')
fi

menu="${toggle_entry}
󱚼  Advanced settings…"

if [[ -n "$ssid_list" ]]; then
    menu="${menu}
${ssid_list}"
fi

chosen=$(printf "%s" "$menu" | rofi -dmenu -i -p "WiFi" \
    -font "JetBrainsMono Nerd Font 12" \
    -theme-str 'window { width: 30%; }')

[[ -z "$chosen" ]] && exit 0

case "$chosen" in
    *"Disable WiFi")
        nmcli radio wifi off
        exit 0
        ;;
    *"Enable WiFi")
        nmcli radio wifi on
        exit 0
        ;;
    *"Advanced settings"*)
        nm-connection-editor &
        exit 0
        ;;
esac

# Extract SSID: drop leading marker+spaces, then strip trailing "  [sec] NN%".
ssid=$(printf "%s" "$chosen" | sed -E 's/^[^ ]+  //; s/  \[[^]]*\] [0-9]+%$//')
[[ -z "$ssid" ]] && exit 0

# If a saved connection with this name exists, bring it up. Otherwise ask for a password when needed.
if nmcli -t -f NAME connection show 2>/dev/null | grep -Fxq "$ssid"; then
    if nmcli connection up id "$ssid" >/dev/null 2>&1; then
        notify "Connected" "$ssid"
    else
        notify "Connection failed" "$ssid"
    fi
    exit 0
fi

security=$(printf "%s" "$chosen" | sed -nE 's/.*\[([^]]*)\].*/\1/p')
if [[ -n "$security" && "$security" != "open" && "$security" != "--" ]]; then
    password=$(printf "" | rofi -dmenu -password -p "Password for $ssid" \
        -theme-str 'window { width: 30%; }')
    [[ -z "$password" ]] && exit 0
    if nmcli device wifi connect "$ssid" password "$password" >/dev/null 2>&1; then
        notify "Connected" "$ssid"
    else
        notify "Connection failed" "$ssid"
    fi
else
    if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
        notify "Connected" "$ssid"
    else
        notify "Connection failed" "$ssid"
    fi
fi
