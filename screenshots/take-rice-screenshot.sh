#!/bin/bash

# Rice screenshot script
# Takes clean + busy desktop screenshots (single monitor)

SCREENSHOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TERMINAL="kitty"
MONITOR="HDMI-1"

# Get monitor geometry (WxH+X+Y)
read -r W H X Y <<< "$(xrandr --query | grep "$MONITOR" | grep -oP '(\d+)x(\d+)\+(\d+)\+(\d+)' | sed 's/[x+]/ /g')"

echo "=== Rice Screenshot ==="
echo "Monitor: $MONITOR (${W}x${H}+${X}+${Y})"

# 1. Clean screenshot — switch to empty workspace
echo "[1/2] Clean desktop..."
i3-msg "focus output $MONITOR"
i3-msg "workspace 6"
sleep 1
flameshot full --region "${W}x${H}+${X}+${Y}" -p "$SCREENSHOT_DIR/"
mv "$SCREENSHOT_DIR"/*.png "$SCREENSHOT_DIR/clean.png" 2>/dev/null
echo "  -> clean.png saved"

# 2. Busy screenshot — open tiled terminals
echo "[2/2] Busy desktop..."
i3-msg "focus output $MONITOR"
i3-msg "workspace 6"
sleep 0.5

# Left: fastfetch
$TERMINAL --title "fastfetch" -e bash -c "fastfetch; read -r" &
sleep 1

# Split right
i3-msg "split h"

# Right top: htop
$TERMINAL --title "htop" -e bash -c "htop" &
sleep 1

# Split bottom right
i3-msg "split v"

# Right bottom: cmatrix
$TERMINAL --title "cmatrix" -e bash -c "cmatrix -s -C cyan" &
sleep 2

# Take screenshot
flameshot full --region "${W}x${H}+${X}+${Y}" -p "$SCREENSHOT_DIR/"
# Rename latest screenshot
LATEST=$(ls -t "$SCREENSHOT_DIR"/*.png 2>/dev/null | grep -v -E "clean|busy|take" | head -1)
[ -n "$LATEST" ] && mv "$LATEST" "$SCREENSHOT_DIR/busy.png"
echo "  -> busy.png saved"

# Cleanup — close opened windows
i3-msg '[title="fastfetch"] kill'
i3-msg '[title="htop"] kill'
i3-msg '[title="cmatrix"] kill'

echo "Done! Screenshots in $SCREENSHOT_DIR/"
