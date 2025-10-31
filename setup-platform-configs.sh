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

echo ""
echo "Platform-specific configuration complete!"
echo ""
echo "Note: Run this script after 'stow . --dotfiles --target \$HOME'"

