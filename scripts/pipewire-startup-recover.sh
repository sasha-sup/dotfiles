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
        # With no usable default source these fail; that must not mask the sink recovery below.
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 || true
        wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 1.0 || true
    fi
}

has_default_sink() {
    wpctl inspect @DEFAULT_AUDIO_SINK@ >/dev/null 2>&1
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

# The card can also be listed but unusable: ALSA open returns "Device or resource busy" at startup,
# the sinks stay "not ready" and WirePlumber never picks a default, so every stream goes nowhere.
# Restarting WirePlumber alone reopens the card; pipewire itself is left alone so the filter-chain
# daemon bound to it keeps running.
if ! has_default_sink; then
    systemctl --user restart wireplumber
    sleep 3
    has_default_sink || echo "no default audio sink after wireplumber restart; check: wpctl status" >&2
fi

set_default_digital_mic
