#!/bin/bash

# Rice screenshot script
# Takes clean + busy desktop screenshots (single monitor)

SCREENSHOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TERMINAL="kitty"
# Use the primary output, or the first connected one if none is marked primary
MONITOR="${MONITOR:-$(xrandr --query | grep -m1 " connected primary" | cut -d' ' -f1)}"
MONITOR="${MONITOR:-$(xrandr --query | grep -m1 " connected" | cut -d' ' -f1)}"

# Get monitor geometry (WxH+X+Y)
read -r W H X Y <<< "$(xrandr --query | grep "^$MONITOR " | grep -oP '(\d+)x(\d+)\+(\d+)\+(\d+)' | sed 's/[x+]/ /g')"

echo "=== Rice Screenshot ==="
echo "Monitor: $MONITOR (${W}x${H}+${X}+${Y})"

# Capture the monitor area straight into a named file.
# ImageMagick is used instead of flameshot so no desktop notification
# pops up in the middle of the next shot.
capture() {
    import -window root -crop "${W}x${H}+${X}+${Y}" +repage "$1"
}

# 1. Clean screenshot — switch to empty workspace
echo "[1/2] Clean desktop..."
i3-msg "focus output $MONITOR"
i3-msg "workspace 6"
sleep 1
capture "$SCREENSHOT_DIR/clean.png"
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
capture "$SCREENSHOT_DIR/busy.png"
echo "  -> busy.png saved"

# Cleanup — close opened windows
i3-msg '[title="fastfetch"] kill'
i3-msg '[title="htop"] kill'
i3-msg '[title="cmatrix"] kill'

echo "Done! Screenshots in $SCREENSHOT_DIR/"
