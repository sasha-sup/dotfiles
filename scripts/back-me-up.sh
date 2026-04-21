#!/bin/bash
# Snapshot backup for files NOT managed by dotfiles repo.
# Dotfiles (i3, kitty, picom, polybar, zshrc, p10k.zsh) live in ~/Code/private/dotfiles.
# This script captures system files and user state that dotfiles does not cover.

. "${DOTFILES_ENV:-$HOME/.config/dotfiles.env}" 2>/dev/null || true

BASE_DIR="${BACKUP_BASE_DIR:-$HOME/backups}"
CONF_DIR="$HOME/.config"
DATE=$(date +"%Y-%m-%d")

mkdir -p "$BASE_DIR"

declare -A CONFIG_FILES=(
    # --- System files (not in dotfiles) ---
    ["/etc/i3status.conf"]="i3status_conf"
    ["/etc/hosts"]="etc_hosts"
    ["/etc/rkhunter.conf"]="rkhunter_conf"
    ["/etc/sudoers.d/$USER"]="user_sudoers"

    # --- User configs NOT in dotfiles ---
    ["$HOME/.bashrc"]="bashrc"
    ["$HOME/.p10k.zsh"]="p10k_zsh"
    ["$CONF_DIR/mc"]="mc"
    ["$CONF_DIR/flameshot/flameshot.ini"]="flameshot_ini"
)

# Copy tracked files
for config_file in "${!CONFIG_FILES[@]}"; do
    [ -e "$config_file" ] || { echo "skip (missing): $config_file"; continue; }
    backup_name="${CONFIG_FILES[$config_file]}_backup_$DATE"
    cp -r "$config_file" "$BASE_DIR/$backup_name"
done

# Crontab snapshot
crontab -l > "$BASE_DIR/crontab_$DATE.txt" 2>/dev/null || \
    echo "(no crontab)" > "$BASE_DIR/crontab_$DATE.txt"

# Installed apt packages (so a fresh machine can be restored quickly)
dpkg --get-selections > "$BASE_DIR/dpkg_selections_$DATE.txt"
apt-mark showmanual   > "$BASE_DIR/apt_manual_$DATE.txt"

# Zsh history (valuable muscle memory)
[ -f "$HOME/.zsh_history" ] && cp "$HOME/.zsh_history" "$BASE_DIR/zsh_history_$DATE"

# --- Encrypted secrets (GPG) ---
GPG_RECIPIENT="${GPG_RECIPIENT:?GPG_RECIPIENT not set (see ~/.config/dotfiles.env)}"
SECRETS_DIR="$BASE_DIR/secrets"
mkdir -p "$SECRETS_DIR"

encrypt_dir() {
    local src="$1" name="$2"
    [ -e "$src" ] || { echo "skip secret (missing): $src"; return; }
    tar -czf - -C "$(dirname "$src")" "$(basename "$src")" 2>/dev/null | \
        gpg --yes --batch --trust-model always \
            --encrypt --recipient "$GPG_RECIPIENT" \
            --output "$SECRETS_DIR/${name}_$DATE.tar.gz.gpg"
}

encrypt_dir "$HOME/.ssh"                "ssh"
encrypt_dir "$HOME/.gnupg"              "gnupg"
encrypt_dir "$HOME/.kube"               "kube"
encrypt_dir "$HOME/.config/gh"          "gh"
encrypt_dir "$HOME/.aws"                "aws"
encrypt_dir "$HOME/.config/dotfiles.env" "dotfiles_env"

# Encrypted snapshots rotate slower (14 days) since they change rarely
find "$SECRETS_DIR/" -type f -name "*.gpg" -mtime +14 -exec rm {} \;

# Rotate: drop plain snapshots older than 3 days (secrets dir handled above)
find "$BASE_DIR/" -maxdepth 1 -type f -name "*_*" -mtime +3 -exec rm {} \;

# Push backup repo
[ -x "$HOME/.local/bin/push-my-dir.sh" ] && bash "$HOME/.local/bin/push-my-dir.sh"

# Telegram notification (optional)
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$message"
}

if [ -n "${NOTIFY_ENV_FILE:-}" ] && [ -f "$NOTIFY_ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$NOTIFY_ENV_FILE"
    send_telegram_message "Local config files backuped ($DATE)"
fi
