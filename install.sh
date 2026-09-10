#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SUFFIX="bak-$(date +%Y%m%d%H%M%S)"

echo "=== Dotfiles Installer ==="

# link SRC DEST — symlink DEST to SRC.
# Everything tracked in this repo is symlinked, never copied, so editing the
# repo is the same as editing the live config. A pre-existing real file at DEST
# is moved aside to DEST.bak-<timestamp> instead of being silently destroyed.
link() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "$dest.$BACKUP_SUFFIX"
        echo "  backed up existing $dest -> $dest.$BACKUP_SUFFIX"
    fi
    ln -sfn "$src" "$dest"
}

# system_file SRC DEST — install a repo file into a root-owned location.
# Copied rather than symlinked, unlike everything under $HOME: /etc must not
# depend on this repo staying checked out at this path, and root should not
# follow a link into a tree the user can rewrite. Only touches DEST when the
# content actually differs, so rerunning the script is quiet and asks for sudo
# no more than it has to. Sets SYSTEM_FILES_CHANGED so callers can decide
# whether a service needs restarting.
system_file() {
    local src="$1" dest="$2"
    if sudo cmp -s "$src" "$dest" 2>/dev/null; then
        return 0
    fi
    sudo mkdir -p "$(dirname "$dest")"
    if sudo test -e "$dest"; then
        sudo cp -a "$dest" "$dest.$BACKUP_SUFFIX"
        echo "  backed up existing $dest -> $dest.$BACKUP_SUFFIX"
    fi
    sudo install -m 0644 -o root -g root "$src" "$dest"
    echo "  installed $dest"
    SYSTEM_FILES_CHANGED=1
}

# --- Configs ---
link "$DOTFILES_DIR/i3/config"            "$HOME/.config/i3/config"
link "$DOTFILES_DIR/polybar/config.ini"   "$HOME/.config/polybar/config.ini"
link "$DOTFILES_DIR/polybar/launch.sh"    "$HOME/.config/polybar/launch.sh"
link "$DOTFILES_DIR/polybar/wifi-menu.sh" "$HOME/.config/polybar/wifi-menu.sh"
link "$DOTFILES_DIR/picom/picom.conf"     "$HOME/.config/picom/picom.conf"
link "$DOTFILES_DIR/kitty/kitty.conf"     "$HOME/.config/kitty/kitty.conf"
link "$DOTFILES_DIR/rofi/config.rasi"     "$HOME/.config/rofi/config.rasi"
link "$DOTFILES_DIR/fontconfig/conf.d/01-prefer-color-emoji.conf" \
     "$HOME/.config/fontconfig/conf.d/01-prefer-color-emoji.conf"
# Saved autorandr profiles are EDID-specific and stay machine-local, but the
# hook that re-asserts the single-external-output rule is shared.
link "$DOTFILES_DIR/autorandr/postswitch.d/10-single-external-output" \
     "$HOME/.config/autorandr/postswitch.d/10-single-external-output"

# --- Keyboard layout (system-wide) ---
# Xorg re-reads this on every keyboard device add, so it overrides the setxkbmap
# that i3 runs at startup: a Bluetooth keyboard reconnect was enough to bring the
# old group toggle back. Keep the two in sync — i3/config runs the same options.
SYSTEM_FILES_CHANGED=0
system_file "$DOTFILES_DIR/etc/X11/xorg.conf.d/00-keyboard.conf" \
            /etc/X11/xorg.conf.d/00-keyboard.conf

# --- Private data ---
# dotfiles.env holds hosts, UUIDs and recipients, so it is never committed and
# never symlinked: the repo only ships a template to seed it once.
if [ ! -e "$HOME/.config/dotfiles.env" ]; then
    mkdir -p "$HOME/.config"
    cp "$DOTFILES_DIR/scripts/dotfiles.env.example" "$HOME/.config/dotfiles.env"
    chmod 600 "$HOME/.config/dotfiles.env"
    echo "Created ~/.config/dotfiles.env from the template — fill it in."
fi
# Same for machine-local zsh aliases sourced at the end of zsh/zshrc.
if [ ! -e "$HOME/.zshrc.local" ]; then
    printf '%s\n' \
        '# Machine-local zsh config. Not committed to dotfiles.' \
        '# Personal hosts, internal IPs and per-machine aliases live here.' \
        > "$HOME/.zshrc.local"
fi

# --- Wallpapers ---
link "$DOTFILES_DIR/wallpapers/win-xp-linux.png"      "$HOME/Pictures/wallpapers/win-xp-linux.png"
link "$DOTFILES_DIR/wallpapers/win-xp-linux-blur.png" "$HOME/Pictures/wallpapers/win-xp-linux-blur.png"
# The blur copy is pre-rendered to the panel size because i3lock cannot scale.
link "$DOTFILES_DIR/wallpapers/1zvHQuC4.png"                "$HOME/Pictures/wallpapers/1zvHQuC4.png"
link "$DOTFILES_DIR/wallpapers/1zvHQuC4-blur-1920x1200.png" "$HOME/Pictures/wallpapers/1zvHQuC4-blur-1920x1200.png"

# --- Scripts ---
SCRIPTS_DIR="$HOME/.local/bin"
for script in "$DOTFILES_DIR"/scripts/*.sh; do
    # dotfiles-version.sh is generated, not symlinked. It has to keep working
    # while HEAD sits on a version older than itself — a symlink would dangle in
    # that checkout and leave no way to run 'back'. The copy also has to be told
    # where the repo is, since it can no longer derive that from its own path.
    if [ "$(basename "$script")" = "dotfiles-version.sh" ]; then
        mkdir -p "$SCRIPTS_DIR"
        sed "s|@DOTFILES_DIR@|$DOTFILES_DIR|g" "$script" > "$SCRIPTS_DIR/dotfiles-version.sh"
        chmod +x "$SCRIPTS_DIR/dotfiles-version.sh"
        continue
    fi
    link "$script" "$SCRIPTS_DIR/$(basename "$script")"
done

# --- Desktop entries + icons (AppImage apps) ---
APPS_DIR="$HOME/.local/share/applications"
ICONS_DIR="$HOME/.local/share/icons/hicolor"
mkdir -p "$APPS_DIR"

# Generated, not symlinked: Exec= must be an absolute path, so @HOME@ is
# expanded for the current user instead of being hardcoded in the repo.
sed "s|@HOME@|$HOME|g" "$DOTFILES_DIR/applications/ledger-live-desktop.desktop.in" \
    > "$APPS_DIR/ledger-live-desktop.desktop"

for size in 128x128 256x256 512x512 1024x1024; do
    link "$DOTFILES_DIR/icons/hicolor/$size/apps/ledger-live-desktop.png" \
         "$ICONS_DIR/$size/apps/ledger-live-desktop.png"
done

if [ ! -x "$HOME/.local/bin/ledger" ]; then
    echo "Installing Ledger Live Desktop AppImage..."
    "$DOTFILES_DIR/scripts/ledger-install.sh" || \
        echo "WARNING: Ledger install failed. Run manually: $DOTFILES_DIR/scripts/ledger-install.sh"
fi

update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
gtk-update-icon-cache -f -t "$ICONS_DIR" >/dev/null 2>&1 || true

# --- User services ---
link "$DOTFILES_DIR/systemd/user/pipewire-startup-recover.service" \
     "$HOME/.config/systemd/user/pipewire-startup-recover.service"
systemctl --user daemon-reload >/dev/null 2>&1 || \
    echo "WARNING: systemctl --user daemon-reload failed. Run it after login."
systemctl --user enable pipewire-startup-recover.service >/dev/null 2>&1 || \
    echo "WARNING: pipewire-startup-recover.service was not enabled. Run: systemctl --user enable pipewire-startup-recover.service"

# --- Fan control (ThinkPad T14 Gen 4 only) ---
# The stock EC fan curve latches: once a load raises the fan it never walks it
# back down, so the machine sits at ~3500 RPM and 45 C long after the load is
# gone. thinkfan takes the fan instead and stops it entirely through the idle
# range. The curve in etc/thinkfan.yaml is written against this model's sensor
# names and its 50-53 C idle, so it is gated on the exact machine rather than
# applied to whatever hardware happens to run this script.
if [ "$(cat /sys/class/dmi/id/product_version 2>/dev/null)" = "ThinkPad T14 Gen 4" ]; then
    if [ ! -x /usr/sbin/thinkfan ]; then
        echo "Installing thinkfan..."
        sudo apt install -y thinkfan || \
            echo "WARNING: thinkfan install failed. Run manually: sudo apt install thinkfan"
    fi

    if [ -x /usr/sbin/thinkfan ]; then
        SYSTEM_FILES_CHANGED=0
        system_file "$DOTFILES_DIR/etc/thinkfan.yaml"                 /etc/thinkfan.yaml
        system_file "$DOTFILES_DIR/etc/default/thinkfan"              /etc/default/thinkfan
        system_file "$DOTFILES_DIR/etc/modprobe.d/thinkfan.conf"      /etc/modprobe.d/thinkfan.conf
        system_file "$DOTFILES_DIR/etc/modules-load.d/thinkfan.conf"  /etc/modules-load.d/thinkfan.conf
        system_file "$DOTFILES_DIR/etc/systemd/system/thinkfan.service.d/10-restart.conf" \
                    /etc/systemd/system/thinkfan.service.d/10-restart.conf

        # thinkpad_acpi refuses to hand the fan to userspace unless it was
        # loaded with fan_control=1, and it reads that only at load time. The
        # reload fails if something holds the module; a reboot covers that.
        if [ "$(cat /sys/module/thinkpad_acpi/parameters/fan_control 2>/dev/null)" != "Y" ]; then
            sudo modprobe -r thinkpad_acpi && sudo modprobe thinkpad_acpi || \
                echo "WARNING: could not reload thinkpad_acpi. Fan control starts after the next reboot."
        fi

        if [ "$SYSTEM_FILES_CHANGED" = 1 ]; then
            sudo systemctl daemon-reload
        fi
        sudo systemctl enable thinkfan.service >/dev/null 2>&1 || \
            echo "WARNING: could not enable thinkfan.service."
        if [ "$SYSTEM_FILES_CHANGED" = 1 ] || ! systemctl is-active --quiet thinkfan.service; then
            sudo systemctl restart thinkfan.service || \
                echo "WARNING: thinkfan.service did not start. Check with: systemctl status thinkfan"
        fi
    fi
fi

# --- Fonts (MesloLGS NF for Powerlevel10k) ---
FONT_DIR="$HOME/.local/share/fonts"
for font in "$DOTFILES_DIR"/fonts/*.ttf; do
    [ -e "$font" ] || continue
    link "$font" "$FONT_DIR/$(basename "$font")"
done
fc-cache -f "$FONT_DIR" >/dev/null

# --- Zsh + Oh My Zsh ---
if ! command -v zsh >/dev/null 2>&1; then
    echo "WARNING: zsh is not installed. Install it first: sudo apt install zsh"
fi

# --- fzf (fuzzy finder for Ctrl-R / Ctrl-T / Alt-C in zsh) ---
if ! command -v fzf >/dev/null 2>&1; then
    echo "Installing fzf..."
    sudo apt install -y fzf || echo "WARNING: fzf install failed. Run manually: sudo apt install fzf"
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# Powerlevel10k
[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "$ZSH_CUSTOM/themes/powerlevel10k"

# Plugins
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# Zsh configs
link "$DOTFILES_DIR/zsh/zshrc"    "$HOME/.zshrc"
link "$DOTFILES_DIR/zsh/p10k.zsh" "$HOME/.p10k.zsh"

# Default shell
ZSH_BIN="$(command -v zsh || true)"
if [ -n "$ZSH_BIN" ] && [ "$SHELL" != "$ZSH_BIN" ]; then
    echo "Switching default shell to zsh (may prompt for password)..."
    chsh -s "$ZSH_BIN" || echo "WARNING: chsh failed. Run it manually: chsh -s $ZSH_BIN"
fi

echo "Done! Restart i3 with Alt+Shift+r, or open a new terminal for zsh."
