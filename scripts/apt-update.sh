#!/usr/bin/env bash
# Update the system: apt packages, oh-my-zsh, global npm packages, Claude Code, oh-my-claudecode,
# oh-my-codex, uv tools and the Rust toolchain. Report pending firmware and whether a reboot is needed.
set -euo pipefail

if [[ -t 1 ]]; then
    BOLD=$'\e[1m' BLUE=$'\e[34m' GREEN=$'\e[32m' YELLOW=$'\e[33m' RED=$'\e[31m' RESET=$'\e[0m'
else
    BOLD='' BLUE='' GREEN='' YELLOW='' RED='' RESET=''
fi

log_section() { printf '\n%s==>%s %s%s%s\n' "$BLUE" "$RESET" "$BOLD" "$*" "$RESET"; }
log_success() { printf '%s✔%s %s\n' "$GREEN" "$RESET" "$*"; }
log_warning() { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
trap 'printf "%s✘ Update failed (line %s)%s\n" "$RED" "$LINENO" "$RESET" >&2' ERR

log_section "Refreshing package lists..."
sudo apt-get update -qq
log_success "Package lists updated"

log_section "Available updates:"
mapfile -t upgradable < <(apt list --upgradable 2>/dev/null | tail -n +2)
if (( ${#upgradable[@]} == 0 )); then
    log_success "System is up to date"
else
    printf '  %s\n' "${upgradable[@]}"
    printf '%s%d package(s) to upgrade%s\n' "$BOLD" "${#upgradable[@]}" "$RESET"

    log_section "Installing updates..."
    sudo apt-get upgrade -y
    log_success "Updates installed"
fi

log_section "Removing unused packages and cleaning cache..."
sudo apt-get autoremove -y -qq
sudo apt-get autoclean -qq
log_success "System cleaned"

# User-level tools: a failure here is reported but does not stop the rest of the update.
run_step() {
    local name=$1; shift
    if "$@"; then
        log_success "$name updated"
    else
        log_warning "$name update failed, rerun by hand: $*"
    fi
}

update_oh_my_zsh() {
    ZSH="$HOME/.oh-my-zsh" zsh "$HOME/.oh-my-zsh/tools/upgrade.sh" || return 1
    # Custom plugins and themes (powerlevel10k, zsh-autosuggestions, ...) are separate git clones.
    local repo
    for repo in "$HOME"/.oh-my-zsh/custom/{plugins,themes}/*/; do
        [[ -d "$repo/.git" ]] || continue
        printf '  %s\n' "$(basename "$repo")"
        git -C "$repo" pull --ff-only -q || return 1
    done
}

# `npm update -g` stays within the current major version, so install each outdated package @latest.
update_npm_globals() {
    local -a outdated
    # npm outdated exits 1 when something is outdated; format: path:wanted:current:latest:dependent
    mapfile -t outdated < <(npm outdated -g --parseable 2>/dev/null | cut -d: -f4 || true)
    if (( ${#outdated[@]} == 0 )); then
        printf '  all global packages are up to date\n'
        return 0
    fi
    printf '  %s\n' "${outdated[@]}"
    npm install -g "${outdated[@]}"
}

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_section "Updating oh-my-zsh..."
    run_step "oh-my-zsh" update_oh_my_zsh
fi

if command -v npm >/dev/null; then
    log_section "Updating global npm packages..."
    run_step "Global npm packages" update_npm_globals
fi

if command -v claude >/dev/null; then
    log_section "Updating Claude Code..."
    run_step "Claude Code" claude update
fi

if command -v omc >/dev/null; then
    log_section "Updating oh-my-claudecode..."
    run_step "oh-my-claudecode" omc update
fi

if command -v omx >/dev/null; then
    log_section "Updating oh-my-codex..."
    run_step "oh-my-codex" omx update
fi

if command -v uv >/dev/null; then
    log_section "Updating uv tools..."
    run_step "uv tools" uv tool upgrade --all
fi

if command -v rustup >/dev/null; then
    log_section "Updating Rust toolchain..."
    run_step "Rust toolchain" rustup update
fi

# Firmware is only reported: flashing usually needs a reboot, so run `fwupdmgr update` by hand.
if command -v fwupdmgr >/dev/null && command -v python3 >/dev/null; then
    log_section "Checking firmware updates..."
    # refresh exits 2 when the metadata is already current
    fwupdmgr refresh --no-unreported-check </dev/null >/dev/null 2>&1 || true
    mapfile -t firmware < <(fwupdmgr get-updates --json --no-unreported-check </dev/null 2>/dev/null \
        | python3 -I -c '
import json, sys
for dev in json.load(sys.stdin).get("Devices", []):
    for release in dev.get("Releases", [])[:1]:
        print(dev.get("Name"), dev.get("Version"), "->", release.get("Version"))
' 2>/dev/null || true)
    if (( ${#firmware[@]} == 0 )); then
        log_success "Firmware is up to date"
    else
        printf '  %s\n' "${firmware[@]}"
        log_warning "Firmware updates available, install with: fwupdmgr update"
    fi
fi

log_section "Update completed"

# Debian/Ubuntu flag file, plus a fallback: running kernel is older than the newest installed one.
newest_kernel=$(find /boot -maxdepth 1 -name 'vmlinuz-*' -printf '%f\n' 2>/dev/null \
    | sed 's/^vmlinuz-//' | sort -V | tail -n 1)
if [[ -f /var/run/reboot-required ]] || [[ -n "$newest_kernel" && "$newest_kernel" != "$(uname -r)" ]]; then
    log_warning "${BOLD}System needs a reboot, do it ASAP${RESET}"
    if [[ -f /var/run/reboot-required.pkgs ]]; then
        sort -u /var/run/reboot-required.pkgs | sed 's/^/  /'
    fi
else
    log_success "No reboot needed"
fi
