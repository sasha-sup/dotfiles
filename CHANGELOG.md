# Changelog

Versions are git tags. `dotfiles-version.sh switch <tag>` checks one out and reloads
the desktop; `dotfiles-version.sh back` returns to `master`.

## v1.0.0 — 2026-08-19

_Win XP / synthwave rice_

Everything up to the purple retint, summarised rather than listed commit by commit:

- i3 + polybar + picom + rofi + kitty rice on Debian Trixie, Win XP / Linux mashup wallpaper.
- Zsh with Oh My Zsh, Powerlevel10k, fzf key bindings and MesloLGS NF fonts.
- Polybar modules: network, bluetooth, CPU, temperature, fan, memory, battery with time
  remaining, volume, weather. Rofi wifi picker on left-click.
- Personal scripts moved into the repo and installed to `~/.local/bin/`, with hosts, UUIDs
  and device names externalised to `~/.config/dotfiles.env`.
- Backups: 3-day plaintext rotation, GPG-encrypted secrets, NVMe SMART watchdog.
- libvirt VM toggle on its own tabbed workspace; Ledger Live desktop entry and installer.
- `install.sh` switched from copying to symlinking every tracked file.
