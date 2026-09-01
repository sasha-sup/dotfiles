# Changelog

Versions are git tags. `dotfiles-version.sh switch <tag>` checks one out and reloads
the desktop; `dotfiles-version.sh back` returns to `master`.

## v2.0.0 — 2026-09-01

_Neon purple rice: new wallpaper, translucent bar, uniform gaps_

- feat(theme): retint kitty, rofi, polybar and i3 to the purple palette
- fix(kitty): lift color0 and color8 so dim text stays visible
- feat(i3): switch desktop and lock images to the neon shot
- feat(polybar): make the bar translucent and blur only behind it
- feat(kitty): show the desktop picture behind the terminal
- style(kitty): raise the background tint so the picture sits further back
- style(kitty): dim the background picture further
- feat(wallpapers): ship the neon pictures with the repo
- style(i3,polybar): use a uniform 10px gap around every window
- fix(screenshots): detect the monitor and capture without a notification
- chore(screenshots): retake the desktop shots on the neon rice
- feat(scripts): version the rice with git tags
- fix(scripts): install dotfiles-version.sh as a copy, not a symlink
- docs(readme): note that dotfiles-version.sh is copied, not symlinked

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
