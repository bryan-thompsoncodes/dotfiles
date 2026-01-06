#!/usr/bin/env bash
# Platform-specific dotfile configuration setup
# This script handles platform-specific overrides for dotfiles managed with stow

set -e

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
else
    echo "Unknown platform: $OSTYPE"
    exit 1
fi

echo "Detected platform: $PLATFORM"

# Alacritty configuration
echo ""
echo "Setting up Alacritty for $PLATFORM..."

ALACRITTY_CONFIG="$HOME/.config/alacritty/alacritty.toml"

if [[ "$PLATFORM" == "linux" ]]; then
    # Create symlink to Linux-specific config
    ln -sf alacritty-linux.toml "$ALACRITTY_CONFIG"
    echo "  Linked alacritty.toml -> alacritty-linux.toml"
    
elif [[ "$PLATFORM" == "macos" ]]; then
    # Create symlink to macOS-specific config
    ln -sf alacritty-macos.toml "$ALACRITTY_CONFIG"
    echo "  Linked alacritty.toml -> alacritty-macos.toml"
fi

# Tmux plugin setup
echo ""
echo "Setting up Tmux plugins..."

TMUX_PLUGINS_DIR="$HOME/.tmux/plugins"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_PLUGINS_DIR="$REPO_ROOT/dot-tmux/plugins"

resolve_path() {
    perl -MCwd -le 'print Cwd::abs_path($ARGV[0])' "$1"
}

if [[ ! -d "$REPO_PLUGINS_DIR" ]]; then
    echo "  ERROR: Expected plugin source directory at $REPO_PLUGINS_DIR was not found."
    echo "  Ensure the repository is intact before re-running this script."
elif [[ -L "$TMUX_PLUGINS_DIR" ]]; then
    LINK_TARGET="$(resolve_path "$TMUX_PLUGINS_DIR")"
    SOURCE_TARGET="$(resolve_path "$REPO_PLUGINS_DIR")"
    if [[ "$LINK_TARGET" == "$SOURCE_TARGET" ]]; then
        echo "  ~/.tmux/plugins already points at the vendored plugins. Nothing to do."
    else
        echo "  WARNING: ~/.tmux/plugins points to $LINK_TARGET (expected $SOURCE_TARGET)."
        echo "  Leaving the existing link untouched to avoid clobbering local data."
    fi
elif [[ -e "$TMUX_PLUGINS_DIR" ]]; then
    echo "  WARNING: Found a real directory at ~/.tmux/plugins."
    echo "  Skipping auto-link to keep your local plugins intact."
    echo "  Remove or move that directory if you want to use the vendored plugins."
else
    ln -s "$REPO_PLUGINS_DIR" "$TMUX_PLUGINS_DIR"
    echo "  Linked ~/.tmux/plugins -> $REPO_PLUGINS_DIR"
fi

# Secrets directory setup
echo ""
echo "Setting up secrets directory..."

SECRETS_DIR="$HOME/.secrets"

if [[ ! -d "$SECRETS_DIR" ]]; then
    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"
    echo "  Created $SECRETS_DIR with restricted permissions (700)"
else
    echo "  $SECRETS_DIR already exists"
fi

# OpenCode API key from Keychain (macOS only)
OPENCODE_SECRET_FILE="$SECRETS_DIR/opencode-api-key"

if [[ ! -f "$OPENCODE_SECRET_FILE" ]]; then
    if [[ "$PLATFORM" == "macos" ]]; then
        echo "  Attempting to retrieve OpenCode API key from Keychain..."
        if API_KEY=$(security find-generic-password -a "$LOGNAME" -s ai.thompson.codes-openwebui -w 2>/dev/null); then
            echo "$API_KEY" > "$OPENCODE_SECRET_FILE"
            chmod 600 "$OPENCODE_SECRET_FILE"
            echo "  Wrote API key to $OPENCODE_SECRET_FILE from Keychain"
        else
            echo "  No Keychain entry found for ai.thompson.codes-openwebui"
            echo "  To add your API key to Keychain, run:"
            echo "    security add-generic-password -a \"\$LOGNAME\" -s ai.thompson.codes-openwebui -w '<api-key>'"
            echo "  Then re-run this script, or manually create $OPENCODE_SECRET_FILE"
        fi
    else
        echo "  Please create $OPENCODE_SECRET_FILE with your OpenCode API key"
    fi
else
    echo "  $OPENCODE_SECRET_FILE already exists"
fi

# OpenCode AGENTS.md (stow can't selectively ignore root vs nested AGENTS.md)
echo ""
echo "Setting up OpenCode AGENTS.md..."

OPENCODE_AGENTS_SRC="$REPO_ROOT/dot-config/opencode/AGENTS.md"
OPENCODE_AGENTS_DEST="$HOME/.config/opencode/AGENTS.md"

if [[ -L "$OPENCODE_AGENTS_DEST" ]]; then
    echo "  $OPENCODE_AGENTS_DEST already symlinked"
elif [[ -f "$OPENCODE_AGENTS_DEST" ]]; then
    echo "  WARNING: $OPENCODE_AGENTS_DEST exists as regular file, skipping"
else
    ln -s "$OPENCODE_AGENTS_SRC" "$OPENCODE_AGENTS_DEST"
    echo "  Linked $OPENCODE_AGENTS_DEST -> $OPENCODE_AGENTS_SRC"
fi

echo ""
echo "Platform-specific configuration complete!"
echo ""
echo "Note: Run this script after 'stow . --dotfiles --target \$HOME'"
echo ""
echo "Additional manual steps:"
echo "  - GPG: ln -s ~/code/dotfiles/dot-gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf"
echo "  - Tmux: Run 'tmux source-file ~/.tmux.conf' if tmux is already running"

