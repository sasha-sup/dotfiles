#!/bin/bash
# Interactive picker of SSH connection scripts.
# Directory with the scripts comes from ~/.config/dotfiles.env (SSH_SCRIPTS_DIR).

. "${DOTFILES_ENV:-$HOME/.config/dotfiles.env}" 2>/dev/null || true

SCRIPT_DIR="${SSH_SCRIPTS_DIR:?SSH_SCRIPTS_DIR not set (see ~/.config/dotfiles.env)}"

list_scripts() {
  echo "Available SSH connections:"
  local i=1
  for script in "$SCRIPT_DIR"/*; do
    echo "$i) $(basename "$script")"
    ((i++))
  done
}

get_script_by_number() {
  local i=1
  for script in "$SCRIPT_DIR"/*; do
    if [ "$i" -eq "$1" ]; then
      echo "$script"
      return
    fi
    ((i++))
  done
}

list_scripts

read -p "Enter SSH connection numer: " script_number

selected_script=$(get_script_by_number "$script_number")

if [ -z "$selected_script" ]; then
  echo "Error. No such SSH connection."
  exit 1
fi

echo "Execuitng $selected_script"
bash "$selected_script"
