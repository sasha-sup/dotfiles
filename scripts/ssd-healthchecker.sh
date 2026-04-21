#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090
. "${DOTFILES_ENV:-$HOME/.config/dotfiles.env}" 2>/dev/null || true
if [ -n "${NOTIFY_ENV_FILE:-}" ] && [ -f "$NOTIFY_ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$NOTIFY_ENV_FILE"
fi

DEVICE="${1:-${SSD_DEVICE:-/dev/nvme0n1}}"
STATE_DIR="/var/lib/nvme-watch"
STATE_FILE="$STATE_DIR/state"
LOG_FILE="/var/log/nvme-watch.log"
TAG="nvme-watch"

mkdir -p "$STATE_DIR"
touch "$STATE_FILE"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

require() { command -v "$1" >/dev/null 2>&1 || { echo "$1 not found"; exit 1; }; }
require smartctl
require logger

# Collect fresh SMART/health
RAW="$(smartctl -a "$DEVICE" || true)"

# Extract fields (strip commas/spaces)
get_num() { echo "$RAW" | grep -m1 "$1" | awk '{print $NF}' | tr -d ',%' || echo ""; }
get_hex() { echo "$RAW" | grep -m1 "$1" | awk '{print $NF}' || echo ""; }

ERR_COUNT="$(get_num 'Error Information Log Entries:')"
PERCENT_USED="$(get_num 'Percentage Used:')"
MEDIA_ERR="$(get_num 'Media and Data Integrity Errors:')"
CRIT_WARN="$(get_hex 'Critical Warning:')"
POH="$(get_num 'Power On Hours:')"
HEALTH_LINE="$(echo "$RAW" | grep -m1 'SMART overall-health self-assessment' || true)"

timestamp() { date -Is; }

log() {
  local msg="$1"
  echo "$(timestamp) $msg" | tee -a "$LOG_FILE" | logger -t "$TAG"
}


send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$message"
}

fail_if_empty() {
  local name="$1" val="$2"
  if [[ -z "$val" ]]; then
    log "WARN: Could not parse $name from smartctl output."
  fi
}

fail_if_empty "ERR_COUNT" "$ERR_COUNT"
fail_if_empty "PERCENT_USED" "$PERCENT_USED"
fail_if_empty "MEDIA_ERR" "$MEDIA_ERR"
fail_if_empty "CRIT_WARN" "$CRIT_WARN"
fail_if_empty "POH" "$POH"

# Load previous state (if any)
declare -A PREV=()
if [[ -s "$STATE_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$STATE_FILE"
  # PREV_* variables become available
fi

prev_or_zero() { eval "echo \${$1:-0}"; }
PREV_ERR_COUNT="$(prev_or_zero PREV_ERR_COUNT)"
PREV_PERCENT_USED="$(prev_or_zero PREV_PERCENT_USED)"
PREV_MEDIA_ERR="$(prev_or_zero PREV_MEDIA_ERR)"
PREV_POH="$(prev_or_zero PREV_POH)"
PREV_CRIT_WARN="${PREV_CRIT_WARN:-0x00}"
PREV_HEALTH="${PREV_HEALTH:-""}"

# Evaluate changes / alerts
ALERTS=()

# Health line change (PASS -> anything else)
if [[ -n "$HEALTH_LINE" && -n "$PREV_HEALTH" && "$HEALTH_LINE" != "$PREV_HEALTH" ]]; then
  ALERTS+=("Health changed: '$PREV_HEALTH' -> '$HEALTH_LINE'")
fi

# Critical Warning (hex) changed and non-zero now
if [[ "$CRIT_WARN" != "$PREV_CRIT_WARN" ]]; then
  ALERTS+=("Critical Warning changed: $PREV_CRIT_WARN -> $CRIT_WARN")
fi
if [[ "$CRIT_WARN" != "0x00" ]]; then
  ALERTS+=("Critical Warning is non-zero ($CRIT_WARN)")
fi

# Error Information Log Entries increased
if [[ "$ERR_COUNT" =~ ^[0-9]+$ && "$PREV_ERR_COUNT" =~ ^[0-9]+$ ]] && (( ERR_COUNT > PREV_ERR_COUNT )); then
  DIFF=$((ERR_COUNT - PREV_ERR_COUNT))
  ALERTS+=("Error Log increased by +$DIFF (now $ERR_COUNT)")
fi

# Media/Data Integrity Errors increased (should remain 0)
if [[ "$MEDIA_ERR" =~ ^[0-9]+$ && "$PREV_MEDIA_ERR" =~ ^[0-9]+$ ]] && (( MEDIA_ERR > PREV_MEDIA_ERR )); then
  DIFF=$((MEDIA_ERR - PREV_MEDIA_ERR))
  ALERTS+=("Media/Data Integrity Errors increased by +$DIFF (now $MEDIA_ERR)")
fi

# Percentage Used increased notably (wear)
if [[ "$PERCENT_USED" =~ ^[0-9]+$ && "$PREV_PERCENT_USED" =~ ^[0-9]+$ ]] && (( PERCENT_USED > PREV_PERCENT_USED )); then
  DIFF=$((PERCENT_USED - PREV_PERCENT_USED))
  ALERTS+=("Wear increased by +$DIFF% (now ${PERCENT_USED}%)")
fi

# Always log a concise snapshot
log "Snapshot $DEVICE | POH=${POH}h | Health='${HEALTH_LINE:-unknown}' | CritWarn=${CRIT_WARN} | Err=${ERR_COUNT} | MediaErr=${MEDIA_ERR} | Wear=${PERCENT_USED}%"

# Emit alerts if any
if (( ${#ALERTS[@]} )); then
  for a in "${ALERTS[@]}"; do
    log "ALERT: $a"
  done
  send_telegram_message "$(printf '%s\n' "${ALERTS[@]}")"
fi

# Save current state
cat > "$STATE_FILE" <<EOF
PREV_ERR_COUNT="$ERR_COUNT"
PREV_PERCENT_USED="$PERCENT_USED"
PREV_MEDIA_ERR="$MEDIA_ERR"
PREV_POH="$POH"
PREV_CRIT_WARN="$CRIT_WARN"
PREV_HEALTH="$HEALTH_LINE"
EOF
