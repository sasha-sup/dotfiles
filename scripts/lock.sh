#!/bin/bash
# The one screen locker, used by both entry points: xss-lock before suspend and
# the $mod+Shift+X binding. They used to be two separate i3lock command lines in
# i3/config and drifted apart — one grew --tiling, the other did not, and the
# suspend lock left a grey band across the laptop panel for weeks.
set -euo pipefail

# Panel-sized, and that is on purpose: i3lock-color anchors the image at each
# RandR output's own origin, so both monitors of the stacked 1920x2280 screen
# get it from their own top-left. Measured, not assumed — screen rows 2160-2259
# match image rows 1080-1179 exactly, and the only brightness step across the
# whole screen is at y=1080, which is the monitor boundary itself.
#
# A taller image made for the whole screen is wrong here: its rows past 1200
# never get drawn on the panel, and the part that repeats shows up as a second
# seam two thirds down the laptop screen.
#
# Dimmed as well as blurred. Blur alone was not enough: the wallpaper is neon on
# black, and over the bright stripes the date and the layout readout were
# unreadable at any weight.
image="$HOME/Pictures/wallpapers/1zvHQuC4-lock-1920x1200.png"

# i3lock-color is built from source (scripts/i3lock-color-install.sh), not
# packaged, so a dist-upgrade that moves a library ABI can leave it unable to
# start. Falling back to the packaged i3lock keeps the screen locked — plain,
# but locked — rather than letting the machine suspend and wake unlocked.
#
# Packaged i3lock 2.15 paints once at the screen origin, not per output, so it
# needs --tiling to reach the bottom of the panel at all; without it the last
# 1080 rows stay unpainted grey. Tiling puts a seam at y=1200. That is the ugly
# half of "plain but locked" and only shows up when the build is broken.
if ! command -v i3lock-color >/dev/null 2>&1; then
    echo "i3lock-color not found, falling back to i3lock" >&2
    exec i3lock --nofork --ignore-empty-password --image "$image" --tiling
fi

# Colours are the polybar palette: 311e33 background, 824c8c primary, cb80d8
# accent, a68bab muted foreground, dc3d3d alert. i3lock-color wants RRGGBBAA.
#
# --bar-indicator replaces the default ring with a bar. One minibar, a base only
# 4px thick, so it reads as a line under the text rather than a widget: the ring
# put a circle in the middle of the wallpaper and boxed the clock inside it.
# --ring-color is what the growing minibar takes, and the ringver/ringwrong pair
# still recolours the base while checking and after a bad password.
#
# --indicator keeps it on screen instead of only from the first keypress, so the
# lock screen always shows something to type into.
#
# Every text is placed by hand off ix:iy, the indicator centre. No expression
# uses r any more — there is no radius in bar mode. --bar-pos takes the bar's
# left edge, not its centre, hence the -210 for a 420-wide bar.
#
# Only the clock is outlined. i3lock-color strokes the outline over the fill
# rather than behind it, so on 17-20pt mono it eats the glyph and reads worse
# than no outline at all — tried at 2px, then at 1px, both looked hollow. At
# 56pt the stroke is a small fraction of the stem, so the clock keeps it. The
# dimmed wallpaper is what actually carries legibility here.
#
# --keylayout matters here specifically: the layout is us,ru, and without it a
# password typed in the wrong group just reads as "wrong" with no clue why.
#
# The --pass-*-keys let volume and brightness through while locked. That is a
# deliberate trade: someone at the machine can change the volume without the
# password. Nothing else is passed.
exec i3lock-color \
    --nofork \
    --ignore-empty-password \
    --image "$image" --tiling \
    --clock --indicator \
    --bar-indicator --bar-count 1 --bar-orientation horizontal \
    --bar-total-width 420 --bar-base-width 4 --bar-max-height 20 \
    --bar-pos "ix-210:iy+120" --bar-color 824c8ccc \
    --ring-color cb80d8ff --ringver-color cb80d8ff --ringwrong-color dc3d3dff \
    --time-str "%H:%M" --time-size 56 --time-pos "ix:iy-120" \
    --time-color f5f5f5ff --time-font "JetBrainsMono Nerd Font" \
    --timeoutline-color 1a0f1bcc --timeoutline-width 2 \
    --date-str "%A, %d %B" --date-size 20 --date-pos "ix:iy-20" \
    --date-color d8c7dcff --date-font "JetBrainsMono Nerd Font" \
    --greeter-text "$(id -un)" --greeter-size 18 --greeter-pos "ix:iy+22" \
    --greeter-color f5f5f5ff --greeter-font "JetBrainsMono Nerd Font" \
    --keylayout 1 --layout-size 17 --layout-pos "ix:iy+60" \
    --layout-color d8c7dcff --layout-font "JetBrainsMono Nerd Font" \
    --verif-text "verifying…" --verif-size 16 --verif-pos "ix:iy+170" \
    --verif-color cb80d8ff --verif-font "JetBrainsMono Nerd Font" \
    --wrong-text "wrong" --wrong-size 16 --wrong-pos "ix:iy+170" \
    --wrong-color dc3d3dff --wrong-font "JetBrainsMono Nerd Font" \
    --noinput-text "no input" \
    --modif-color dc3d3dff --modif-size 15 --modif-pos "ix:iy+200" \
    --show-failed-attempts \
    --pass-media-keys --pass-volume-keys --pass-screen-keys
