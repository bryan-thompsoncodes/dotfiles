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
ALACRITTY_DIR="$HOME/.config/alacritty"
ALACRITTY_CONFIG="$ALACRITTY_DIR/alacritty.toml"
DOTFILES_ALACRITTY="$HOME/code/dotfiles/dot-config/alacritty"

if [[ "$PLATFORM" == "linux" ]]; then
    echo "Setting up Alacritty for Linux..."
    
    # Remove existing config if it exists
    if [[ -e "$ALACRITTY_CONFIG" ]]; then
        rm "$ALACRITTY_CONFIG"
        echo "  Removed existing alacritty.toml"
    fi
    
    # Create symlink to Linux-specific config
    ln -sf "$DOTFILES_ALACRITTY/alacritty-linux.toml" "$ALACRITTY_CONFIG"
    echo "  Created symlink: $ALACRITTY_CONFIG -> alacritty-linux.toml"
    
elif [[ "$PLATFORM" == "macos" ]]; then
    echo "Setting up Alacritty for macOS..."
    
    # Remove existing config if it exists
    if [[ -e "$ALACRITTY_CONFIG" ]]; then
        rm "$ALACRITTY_CONFIG"
        echo "  Removed existing alacritty.toml"
    fi
    
    # Create symlink to macOS-specific config
    ln -sf "$DOTFILES_ALACRITTY/alacritty-macos.toml" "$ALACRITTY_CONFIG"
    echo "  Created symlink: $ALACRITTY_CONFIG -> alacritty-macos.toml"
fi

# Tmux plugin setup
echo ""
echo "Setting up Tmux plugins..."

TMUX_PLUGINS_DIR="$HOME/.tmux/plugins"

# Remove symlinked plugins directory if it exists from stow
if [[ -L "$TMUX_PLUGINS_DIR" ]] || [[ -d "$TMUX_PLUGINS_DIR" ]]; then
    rm -rf "$TMUX_PLUGINS_DIR"
    echo "  Removed existing plugins directory"
fi

# Create local plugins directory
mkdir -p "$TMUX_PLUGINS_DIR"
echo "  Created local plugins directory"

# Clone TPM if not already present
if [[ ! -d "$TMUX_PLUGINS_DIR/tpm" ]]; then
    echo "  Cloning TPM (Tmux Plugin Manager)..."
    git clone --quiet https://github.com/tmux-plugins/tpm "$TMUX_PLUGINS_DIR/tpm"
    echo "  TPM installed"
else
    echo "  TPM already installed"
fi

# Install tmux plugins
if [[ -f "$TMUX_PLUGINS_DIR/tpm/scripts/install_plugins.sh" ]]; then
    echo "  Installing tmux plugins..."
    "$TMUX_PLUGINS_DIR/tpm/scripts/install_plugins.sh" > /dev/null 2>&1
    echo "  Tmux plugins installed"
fi

echo ""
echo "Platform-specific configuration complete!"
echo ""
echo "Note: Run this script after 'stow . --dotfiles --target \$HOME'"
echo ""
echo "Additional manual steps:"
echo "  - GPG: ln -s ~/code/dotfiles/dot-gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf"
echo "  - Tmux: Run 'tmux source-file ~/.tmux.conf' if tmux is already running"

