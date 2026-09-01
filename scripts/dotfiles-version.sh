#!/bin/bash
set -e

# dotfiles-version — move the whole rice between tagged versions.
#
# Every tracked file is symlinked into the repo by install.sh, so checking out
# another tag rewrites the live config in place. Nothing needs reinstalling;
# only the running programs have to reread their files, which `reload` does.

# Find the repo. install.sh expands @DOTFILES_DIR@ in the installed copy,
# because that copy lives in ~/.local/bin and cannot infer the path from its own
# location. Running the file straight out of the repo leaves the placeholder
# unexpanded, and then the script's own directory is the answer.
INSTALLED_DIR="@DOTFILES_DIR@"
if [ -z "$DOTFILES_DIR" ]; then
    if [ -d "$INSTALLED_DIR/.git" ]; then
        DOTFILES_DIR="$INSTALLED_DIR"
    else
        DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
    fi
fi
if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echo "No dotfiles repo at $DOTFILES_DIR. Set DOTFILES_DIR or rerun install.sh." >&2
    exit 1
fi
CHANGELOG="$DOTFILES_DIR/CHANGELOG.md"

git() { command git -C "$DOTFILES_DIR" "$@"; }

# The branch to come back to after test-driving an old version.
main_branch() {
    local head
    head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
    echo "${head#origin/}" | grep . || echo master
}

# Refuse to move HEAD while edits are unsaved: a checkout would either fail
# halfway or carry the changes onto a version they were never written for.
require_clean() {
    if [ -n "$(git status --porcelain)" ]; then
        echo "Uncommitted changes in $DOTFILES_DIR:" >&2
        git status --short >&2
        echo >&2
        echo "Commit or stash them first (git stash), then rerun." >&2
        exit 1
    fi
}

# Where HEAD sits right now: a tag if it points at one, else branch or commit.
current_version() {
    local tag
    tag="$(git describe --tags --exact-match HEAD 2>/dev/null || true)"
    if [ -n "$tag" ]; then
        echo "$tag"
        return
    fi
    local branch
    branch="$(git rev-parse --abbrev-ref HEAD)"
    if [ "$branch" != "HEAD" ]; then
        echo "$branch ($(git describe --tags --abbrev=0 2>/dev/null || echo 'no tag yet'))"
    else
        git rev-parse --short HEAD
    fi
}

# i3 runs picom and polybar from exec_always, so restarting i3 restarts both.
# picom is killed first because a second instance would refuse to start and
# leave the old one running with the previous config.
reload() {
    echo "Reloading desktop..."
    pkill -x picom 2>/dev/null || true
    i3-msg restart >/dev/null 2>&1 || echo "  WARNING: i3 restart failed (not running under i3?)"
    # Kitty rereads kitty.conf on SIGUSR1, so open terminals repaint themselves.
    pkill -USR1 -x kitty 2>/dev/null || true
    echo "  i3, picom, polybar and kitty reloaded"
}

cmd_list() {
    local current
    current="$(git describe --tags --exact-match HEAD 2>/dev/null || true)"
    if [ -z "$(git tag)" ]; then
        echo "No versions yet. Create one: dotfiles-version.sh release v1.0.0 \"description\""
        return
    fi
    git for-each-ref --sort=creatordate \
        --format='%(refname:short)|%(creatordate:short)|%(contents:subject)' refs/tags \
    | while IFS='|' read -r tag date subject; do
        local mark=" "
        if [ "$tag" = "$current" ]; then
            mark="*"
        fi
        printf '%s %-10s %-10s %s\n' "$mark" "$tag" "$date" "$subject"
    done
    echo
    echo "* = currently checked out. Now on: $(current_version)"
}

cmd_switch() {
    local tag="$1"
    [ -n "$tag" ] || { echo "Usage: dotfiles-version.sh switch <tag>" >&2; exit 1; }
    git rev-parse --verify --quiet "refs/tags/$tag" >/dev/null || {
        echo "No such version: $tag" >&2
        echo "Known versions:" >&2
        git tag >&2
        exit 1
    }
    require_clean
    git checkout --quiet "$tag"
    echo "Checked out $tag (detached HEAD — 'back' returns to $(main_branch))"
    reload
}

cmd_back() {
    require_clean
    local branch
    branch="$(main_branch)"
    git checkout --quiet "$branch"
    echo "Back on $branch ($(git describe --tags --abbrev=0 2>/dev/null || echo 'no tag yet'))"
    reload
}

# Cut a new version: write the changelog section from the commits since the
# last tag, commit it, then tag that commit so the tag and its notes agree.
cmd_release() {
    local version="$1" description="$2"
    if [ -z "$version" ] || [ -z "$description" ]; then
        echo 'Usage: dotfiles-version.sh release <version> "<description>"' >&2
        exit 1
    fi
    case "$version" in
        v[0-9]*) ;;
        *) echo "Version must look like v1.2.3, got: $version" >&2; exit 1 ;;
    esac
    if git rev-parse --verify --quiet "refs/tags/$version" >/dev/null; then
        echo "Version $version already exists." >&2
        exit 1
    fi
    [ "$(git rev-parse --abbrev-ref HEAD)" != "HEAD" ] || {
        echo "HEAD is detached. Run 'dotfiles-version.sh back' before releasing." >&2
        exit 1
    }
    require_clean

    local previous range
    previous="$(git describe --tags --abbrev=0 2>/dev/null || true)"
    range="${previous:+$previous..}HEAD"

    local entry
    entry="$(printf '## %s — %s\n\n_%s_\n\n%s\n' \
        "$version" "$(date +%Y-%m-%d)" "$description" \
        "$(git log --reverse --pretty='- %s' "$range")")"

    if [ -f "$CHANGELOG" ]; then
        # Insert above the newest existing section so the title and the intro
        # paragraph stay on top and versions read newest-first below them.
        awk -v entry="$entry" '
            !done && /^## / { print entry "\n"; done = 1 }
            { print }
            END { if (!done) print "\n" entry }
        ' "$CHANGELOG" > "$CHANGELOG.tmp"
        mv "$CHANGELOG.tmp" "$CHANGELOG"
    else
        printf '# Changelog\n\n%s\n' "$entry" > "$CHANGELOG"
    fi

    git add CHANGELOG.md
    git commit --quiet -m "docs(changelog): release $version"
    git tag -a "$version" -m "$description"
    echo "Released $version — $description"
    echo "Push it with: git push origin $(main_branch) && git push origin $version"
}

case "${1:-list}" in
    list)    cmd_list ;;
    current) current_version ;;
    switch)  cmd_switch "$2" ;;
    back)    cmd_back ;;
    release) cmd_release "$2" "$3" ;;
    reload)  reload ;;
    *)
        cat <<'EOF'
Usage: dotfiles-version.sh <command>

  list                      show every version, marking the checked-out one
  current                   print the version HEAD sits on
  switch <tag>              check out a version and reload the desktop
  back                      return to the main branch and reload
  release <ver> "<desc>"    write a changelog section and tag this commit
  reload                    reload i3, picom, polybar and kitty in place
EOF
        exit 1
        ;;
esac
