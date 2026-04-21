#!/bin/bash
# Auto-commit + push a list of repos. Target directories come from
# ~/.config/dotfiles.env (PUSH_TARGET_DIRS array).

. "${DOTFILES_ENV:-$HOME/.config/dotfiles.env}" 2>/dev/null || true

if [ -z "${PUSH_TARGET_DIRS+x}" ] || [ "${#PUSH_TARGET_DIRS[@]}" -eq 0 ]; then
    echo "PUSH_TARGET_DIRS not set (see ~/.config/dotfiles.env)" >&2
    exit 1
fi

for TARGET_DIR in "${PUSH_TARGET_DIRS[@]}"; do
    cd "$TARGET_DIR" || continue
    if git status | grep -q "nothing to commit, working tree clean"; then
        echo "No changes in $TARGET_DIR."
    else
        git add .
        git commit -m "Auto commit"
        git push
        echo "Changes in $TARGET_DIR committed and pushed."
    fi
done
