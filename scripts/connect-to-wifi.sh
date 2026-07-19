#!/bin/bash

# ip link set dev wlp0s20f3 up
# nmcli radio wifi


# Check if NetworkManager is installed
if ! command -v nmcli &> /dev/null; then
    echo "NetworkManager (nmcli) is not installed. Please install it."
    exit 1
fi

# List available Wi-Fi networks
echo "Available Wi-Fi Networks:"
nmcli dev wifi list

# Prompt for SSID and password
read -p "Enter SSID: " SSID
read -sp "Enter password: " password
echo  
clear
# Connect to the specified network
echo "Connecting to $SSID..."
if nmcli dev wifi connect "$SSID" password "$password"; then
    echo "Connected to $SSID successfully."
else
    # A stale profile (wrong/partial saved secret or mismatched security) makes nmcli reuse
    # bad settings. Delete it and retry once with the freshly entered password.
    if nmcli -t -f NAME connection show 2>/dev/null | grep -Fxq "$SSID"; then
        echo "Stale profile detected, removing and retrying..."
        nmcli connection delete id "$SSID" >/dev/null 2>&1
        if nmcli dev wifi connect "$SSID" password "$password"; then
            echo "Connected to $SSID successfully."
        else
            echo "Failed to connect to $SSID. Please check your credentials."
        fi
    else
        echo "Failed to connect to $SSID. Please check your credentials."
    fi
fi
