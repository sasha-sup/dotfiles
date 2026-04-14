#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Dotfiles Installer ==="

# Configs
ln -sfn "$DOTFILES_DIR/i3/config" "$HOME/.config/i3/config"
ln -sfn "$DOTFILES_DIR/polybar/config.ini" "$HOME/.config/polybar/config.ini"
ln -sfn "$DOTFILES_DIR/polybar/launch.sh" "$HOME/.config/polybar/launch.sh"
ln -sfn "$DOTFILES_DIR/picom/picom.conf" "$HOME/.config/picom/picom.conf"
ln -sfn "$DOTFILES_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

# Wallpapers
mkdir -p "$HOME/Pictures/wallpapers"
ln -sfn "$DOTFILES_DIR/wallpapers/win-xp-linux.png" "$HOME/Pictures/wallpapers/win-xp-linux.png"
ln -sfn "$DOTFILES_DIR/wallpapers/win-xp-linux-blur.png" "$HOME/Pictures/wallpapers/win-xp-linux-blur.png"

# Scripts
SCRIPTS_DIR="$HOME/.local/bin"
mkdir -p "$SCRIPTS_DIR"
for script in "$DOTFILES_DIR"/scripts/*.sh; do
    ln -sfn "$script" "$SCRIPTS_DIR/$(basename "$script")"
done

echo "Done! Restart i3 with Alt+Shift+r"
