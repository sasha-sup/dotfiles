#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Dotfiles Installer ==="

# --- Config directories ---
mkdir -p "$HOME/.config/i3" "$HOME/.config/polybar" \
         "$HOME/.config/picom" "$HOME/.config/kitty"

# --- Configs ---
ln -sfn "$DOTFILES_DIR/i3/config"            "$HOME/.config/i3/config"
ln -sfn "$DOTFILES_DIR/polybar/config.ini"   "$HOME/.config/polybar/config.ini"
ln -sfn "$DOTFILES_DIR/polybar/launch.sh"    "$HOME/.config/polybar/launch.sh"
ln -sfn "$DOTFILES_DIR/picom/picom.conf"     "$HOME/.config/picom/picom.conf"
ln -sfn "$DOTFILES_DIR/kitty/kitty.conf"     "$HOME/.config/kitty/kitty.conf"

# --- Wallpapers ---
mkdir -p "$HOME/Pictures/wallpapers"
ln -sfn "$DOTFILES_DIR/wallpapers/win-xp-linux.png"      "$HOME/Pictures/wallpapers/win-xp-linux.png"
ln -sfn "$DOTFILES_DIR/wallpapers/win-xp-linux-blur.png" "$HOME/Pictures/wallpapers/win-xp-linux-blur.png"

# --- Scripts ---
SCRIPTS_DIR="$HOME/.local/bin"
mkdir -p "$SCRIPTS_DIR"
for script in "$DOTFILES_DIR"/scripts/*.sh; do
    ln -sfn "$script" "$SCRIPTS_DIR/$(basename "$script")"
done

# --- Fonts (MesloLGS NF for Powerlevel10k) ---
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
for font in "$DOTFILES_DIR"/fonts/*.ttf; do
    [ -e "$font" ] || continue
    cp -n "$font" "$FONT_DIR/"
done
fc-cache -f "$FONT_DIR" >/dev/null

# --- Zsh + Oh My Zsh ---
if ! command -v zsh >/dev/null 2>&1; then
    echo "WARNING: zsh is not installed. Install it first: sudo apt install zsh"
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
ln -sfn "$DOTFILES_DIR/zsh/zshrc"    "$HOME/.zshrc"
ln -sfn "$DOTFILES_DIR/zsh/p10k.zsh" "$HOME/.p10k.zsh"

# Default shell
ZSH_BIN="$(command -v zsh || true)"
if [ -n "$ZSH_BIN" ] && [ "$SHELL" != "$ZSH_BIN" ]; then
    echo "Switching default shell to zsh (may prompt for password)..."
    chsh -s "$ZSH_BIN" || echo "WARNING: chsh failed. Run it manually: chsh -s $ZSH_BIN"
fi

echo "Done! Restart i3 with Alt+Shift+r, or open a new terminal for zsh."
