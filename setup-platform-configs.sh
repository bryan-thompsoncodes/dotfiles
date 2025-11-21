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

echo ""
echo "Platform-specific configuration complete!"
echo ""
echo "Note: Run this script after 'stow . --dotfiles --target \$HOME'"
echo ""
echo "Additional manual steps:"
echo "  - GPG: ln -s ~/code/dotfiles/dot-gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf"
echo "  - Tmux: Run 'tmux source-file ~/.tmux.conf' if tmux is already running"

