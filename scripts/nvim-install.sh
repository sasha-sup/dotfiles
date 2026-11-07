#!/usr/bin/env bash
set -euo pipefail

# Installs / updates Neovim and the tree-sitter CLI from their GitHub releases.
#
# Not from apt: Debian 13 ships neovim 0.10 and tree-sitter-cli 0.22, while
# LazyVim needs Neovim >= 0.11.2 and nvim-treesitter's main branch needs a
# newer CLI to build parsers. Both land under ~/.local, so no sudo is needed
# and rerunning only downloads what changed.

OPT_DIR="$HOME/.local/opt"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$OPT_DIR" "$BIN_DIR"

TMP_DIR=$(mktemp -d -t nvim-install-XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT

# latest_asset REPO NAME — prints "tag url sha256" for one release asset.
# GitHub publishes the digest per asset, so the download is checked without
# trusting a checksum file fetched over the same connection.
latest_asset() {
    curl -fsSL --max-time 30 "https://api.github.com/repos/$1/releases/latest" |
        jq -r --arg name "$2" \
            '.tag_name as $t | .assets[] | select(.name == $name)
             | "\($t) \(.browser_download_url) \(.digest | sub("^sha256:"; ""))"'
}

# fetch URL SHA256 DEST — download and refuse anything that does not match.
fetch() {
    curl -fL -# --max-time 600 "$1" -o "$3"
    if [ "$(sha256sum "$3" | cut -d' ' -f1)" != "$2" ]; then
        echo "ERROR: sha256 mismatch for $1"
        echo "  Rerun later; if it persists, the release asset changed."
        exit 1
    fi
}

# --- Neovim ---
read -r NVIM_TAG NVIM_URL NVIM_SHA < <(latest_asset neovim/neovim nvim-linux-x86_64.tar.gz)
if [ -z "${NVIM_SHA:-}" ]; then
    echo "ERROR: could not find nvim-linux-x86_64.tar.gz in the latest neovim release."
    echo "  Check https://github.com/neovim/neovim/releases and update the asset name here."
    exit 1
fi

if [ -x "$OPT_DIR/nvim/bin/nvim" ] && \
   "$OPT_DIR/nvim/bin/nvim" --version | head -1 | grep -qx "NVIM $NVIM_TAG"; then
    echo "Neovim $NVIM_TAG already installed"
else
    echo "Installing Neovim $NVIM_TAG..."
    fetch "$NVIM_URL" "$NVIM_SHA" "$TMP_DIR/nvim.tar.gz"
    tar -xzf "$TMP_DIR/nvim.tar.gz" -C "$TMP_DIR"
    # Swap the whole tree: runtime files of the old version must not linger.
    rm -rf "$OPT_DIR/nvim"
    mv "$TMP_DIR/nvim-linux-x86_64" "$OPT_DIR/nvim"
fi
ln -sfn "$OPT_DIR/nvim/bin/nvim" "$BIN_DIR/nvim"

# --- tree-sitter CLI ---
read -r TS_TAG TS_URL TS_SHA < <(latest_asset tree-sitter/tree-sitter tree-sitter-linux-x64.gz)
if [ -z "${TS_SHA:-}" ]; then
    echo "ERROR: could not find tree-sitter-linux-x64.gz in the latest tree-sitter release."
    echo "  Check https://github.com/tree-sitter/tree-sitter/releases and update the asset name here."
    exit 1
fi

if [ -x "$BIN_DIR/tree-sitter" ] && \
   "$BIN_DIR/tree-sitter" --version | grep -q "^tree-sitter ${TS_TAG#v}\b"; then
    echo "tree-sitter $TS_TAG already installed"
else
    echo "Installing tree-sitter $TS_TAG..."
    fetch "$TS_URL" "$TS_SHA" "$TMP_DIR/tree-sitter.gz"
    gunzip "$TMP_DIR/tree-sitter.gz"
    install -m 755 "$TMP_DIR/tree-sitter" "$BIN_DIR/tree-sitter"
fi
