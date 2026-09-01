# AGENTS.md

Working notes for coding agents in this repo. [README.md](README.md) documents the rice itself —
this file only covers what is easy to get wrong from the outside.

## Editing here changes the running desktop

`install.sh` symlinks every tracked file into place, so `i3/config` in this repo **is**
`~/.config/i3/config`. An edit is live the moment it is saved — there is no build, no deploy, and
no "apply" step. Two consequences:

- A broken `i3/config` breaks the window manager on the next reload. Validate before reloading:
  ```bash
  i3 -C -c i3/config                                   # silent + rc 0 means valid
  polybar --config=polybar/config.ini --dump=width main # parses the bar config
  bash -n scripts/<name>.sh                            # shell syntax
  ```
- Changes only take effect once the program rereads its file:
  ```bash
  pkill -x picom; i3-msg restart   # i3 re-execs picom and polybar from exec_always
  pkill -USR1 -x kitty             # kitty rereads kitty.conf
  ```
  `dotfiles-version.sh reload` does all of that in one call.

Three files are deliberately *not* symlinked — see "Symlinks, not copies" in the README. The one
that bites: `scripts/dotfiles-version.sh` is installed as a copy, so editing it does nothing until
`./install.sh` runs again.

## Do not run install.sh to test a small change

It is idempotent, but it also runs `sudo apt install`, `chsh`, clones Oh My Zsh and Powerlevel10k,
and downloads the Ledger AppImage. For a config edit, reload instead. Run it only when the change is
to `install.sh` itself, or when a new file needs linking.

## Never commit personal data

Hosts, IPs, usernames, emails, LUKS UUIDs, VM names, private repo paths and personal ports belong in
`~/.config/dotfiles.env` (untracked, `chmod 600`), with a commented placeholder added to
`scripts/dotfiles.env.example`. Scripts read it as:

```bash
. "${DOTFILES_ENV:-$HOME/.config/dotfiles.env}" 2>/dev/null || true
SSH_HOST="${SSH_PROXY_HOST:?SSH_PROXY_HOST not set (see ~/.config/dotfiles.env)}"
```

Use `:?` so a missing value fails loudly instead of silently doing the wrong thing.

New `i3/config` lines should use `$HOME`, not a hardcoded path. The wallpaper and lock-screen lines
still hardcode `/home/sasha` — that is existing debt, not a pattern to copy.

## Commits

Conventional Commits, matching the existing history: `feat(i3):`, `fix(kitty):`, `style(polybar):`,
`docs(readme):`, `chore(screenshots):`. Scope is the directory being touched. The body explains
*why*, not what the diff already shows.

Never mention Claude, AI, or a co-author in a commit message.

Keep commits atomic: a script fix and the regenerated screenshots it produces are two commits.

## Versions

Each look is a git tag, described in [CHANGELOG.md](CHANGELOG.md). Cut one with:

```bash
dotfiles-version.sh release v2.1.0 "one line describing the look"
git push origin master && git push origin v2.1.0
```

`release` writes the changelog section from the commit subjects since the previous tag, commits it,
and tags that commit — so the tag must be the last thing on the branch. If fixes land after a
release, do not leave the tag behind them; the tag is what `switch` checks out.

Bump major for a new look (wallpaper, palette, bar layout), minor for added config or scripts, patch
for fixes.

`switch` moves HEAD into detached state and refuses to run on a dirty tree. Always return with
`dotfiles-version.sh back` before committing anything new.

## Screenshots

`screenshots/take-rice-screenshot.sh` regenerates `clean.png` and `busy.png`. It hijacks the display
for about ten seconds: it switches to workspace 6, opens three kitty windows, captures, and kills
them. Say so before running it — someone is usually looking at that screen.

It captures with ImageMagick rather than flameshot, because flameshot's save notification landed in
the following shot. The monitor is autodetected from the primary output.

## Shell style

`set -e` at the top of every script, and mind the trap it sets: a bare `cmd && other` that fails
exits the whole script. Use `if`, or append `|| true` where failure is expected. Comments explain
the reason a line exists, not its mechanics — match the density in `install.sh`.
