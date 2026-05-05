#!/usr/bin/env bash
set -euo pipefail

delay="${PIPEWIRE_RECOVER_DELAY_SECONDS:-12}"
sleep "$delay"

status="$(wpctl status 2>/dev/null || true)"

set_default_digital_mic() {
    local mic_id

    mic_id="$(wpctl status 2>/dev/null | sed -n 's/^[^0-9]*\([0-9][0-9]*\)\..*Digital Microphone.*/\1/p' | head -n 1)"
    if [[ -n "$mic_id" ]]; then
        wpctl set-default "$mic_id"
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0
        wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 1.0
    fi
}

if [[ -z "$status" ]]; then
    systemctl --user restart pipewire pipewire-pulse wireplumber
    sleep 2
    set_default_digital_mic
    exit 0
fi

if grep -q "Dummy Output" <<<"$status" && ! grep -Eq " cAVS (Speaker|HDMI)|Built-in Audio|Headphones|HDMI / DisplayPort" <<<"$status"; then
    systemctl --user restart pipewire pipewire-pulse wireplumber
    sleep 2
fi

set_default_digital_mic
