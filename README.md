# Dotfiles

Personal development environment configuration for macOS, managed with GNU Stow.

## Overview

This repository contains dotfiles organized into Stow packages for easy symlinking and management. Configurations are split between:

- `~/` (home directory) for traditional dotfiles
- `~/.config/` for XDG-compliant applications

## Prerequisites

1. **Homebrew** - macOS package manager

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **GNU Stow** - Symlink manager

   ```bash
   brew install stow
   ```

3. **Nix with nix-darwin** (optional) - For system-level package management
   - See [mac-nix-configs](https://github.com/bryan-thompsoncodes/mac-nix-configs) for system configuration

## Installation

From this repository's root directory:

```bash
# Stow individual packages
cd ~/code/dotfiles

# Link shell configuration
stow -v --dotfiles -t ~ zsh

# Link terminal multiplexer config
stow -v --dotfiles -t ~ tmux

# Link Powerlevel10k theme config
stow -v --dotfiles -t ~ p10k

# Link .config directory applications
stow -v -t ~ dot-config
```

Or stow everything at once:

```bash
stow -v --dotfiles -t ~ zsh tmux p10k && stow -v -t ~ dot-config
```

## Structure

```
dotfiles/
├── dot-config/          # XDG config directory (~/.config/)
│   ├── alacritty/       # Terminal emulator
│   ├── bat/             # Cat replacement with syntax highlighting
│   ├── direnv/          # Environment switcher
│   ├── git/             # Git configuration
│   └── nvim/            # Neovim configuration (Lazy.nvim)
├── zsh/                 # Zsh shell (~/.zshrc)
├── tmux/                # Tmux terminal multiplexer (~/.tmux.conf)
├── p10k/                # Powerlevel10k theme (~/.p10k.zsh)
└── zsa-keyboard-layouts/  # ZSA keyboard firmware
```

## Managed Configurations

### Shell (Zsh)

- Powerlevel10k theme (no Oh My Zsh)
- Plugins: zsh-autosuggestions, zsh-syntax-highlighting
- Custom aliases and functions for VA development
- Direnv integration for per-project environments

### Terminal (Alacritty)

- GPU-accelerated terminal
- Custom theme and opacity
- MesloLGS NF font for Powerlevel10k

### Editor (Neovim)

- Lazy.nvim plugin manager
- Custom keybindings and plugins
- LSP and completion setup

### Version Control (Git)

- GPG signing enabled
- Global gitignore for `.envrc` and `.direnv/`

### Tools

- **bat**: Syntax-highlighted cat replacement
- **direnv**: Automatic environment switching
- **tmux**: Terminal multiplexer with vim keybindings

## Updating Configurations

After modifying any dotfiles:

1. Changes are automatically reflected (symlinks point to this repo)
2. For shell changes: `source ~/.zshrc`
3. For tmux changes: `tmux source-file ~/.tmux.conf` or `prefix + r`

## Uninstalling

To remove symlinks:

```bash
cd ~/code/dotfiles
stow -D -t ~ zsh tmux p10k dot-config
```

## Related Repositories

- [mac-nix-configs](https://github.com/bryan-thompsoncodes/mac-nix-configs) - System-level configuration with nix-darwin
  - Homebrew package management
  - Development environment shells (vets-api, vets-website, etc.)
  - System settings

## Notes

- Stow uses relative symlinks by default
- The `--dotfiles` flag converts `dot-` prefix to `.` for files/folders
- ZSA keyboard layouts are stored but not symlinked
