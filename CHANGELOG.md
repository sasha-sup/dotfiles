# Changelog

Versions are git tags. `dotfiles-version.sh switch <tag>` checks one out and reloads
the desktop; `dotfiles-version.sh back` returns to `master`.

## v2.3.0 — 2026-09-10

_a real lock screen: clock, date and the active keyboard layout_

- docs(changelog): describe what v2.1.1 actually changed
- fix(scripts): reject the placeholder release description
- docs(agents): mark the release description as a placeholder
- perf(picom): composite on the iGPU instead of the X server
- feat(etc): install thinkfan from the repo on the T14 Gen 4
- fix(etc): read the chassis sensor thinkfan was silently missing
- fix(etc): stop the fan from stopping, and damp the sensor spikes
- fix(etc): make thinkfan actually survive a boot
- perf(picom): dial the bar blur back to a readable radius
- feat(display): make the laptop panel the primary output
- fix(i3): put suspend back on Fn+F7
- feat(lock): themed lock screen on i3lock-color
- feat(zsh): add gov and kaz work directory aliases

## v2.2.0 — 2026-09-07

_external monitor primary, laptop panel stacked below it_

- fix(display): stop polybar from holding the layout lock
- feat(display): put the laptop panel below the external monitor
- fix(polybar): keep the systray on the primary monitor

## v2.1.1 — 2026-09-07

_the lock screen behaves again: suspend locks, the bar comes back_

- fix(i3): lock the screen on suspend again
- fix(i3): keep the left Win layout toggle after a keyboard hotplug
- fix(i3): move suspend off the left Win key
- fix(polybar): bring the bar back after the lock screen

## v2.1.0 — 2026-09-06

_external monitor is the only output_

- docs(agents): add working notes for coding agents
- feat(i3): switch keyboard layout with left Win key
- fix(display): make the external monitor the only active output
- fix(display): stop re-applying a layout that is already correct

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
