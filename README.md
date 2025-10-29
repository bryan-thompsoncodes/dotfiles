# Dotfiles

Personal development environment configuration for macOS, managed with GNU Stow.

## Overview

This repository contains dotfiles organized into Stow packages for easy symlinking and management. Configurations are split between:

- `~/` (home directory) for traditional dotfiles
- `~/.config/` for XDG-compliant applications

## Prerequisites

### Option A: Using Nix-Darwin (Recommended)

If you're using [mac-nix-configs](https://github.com/bryan-thompsoncodes/mac-nix-configs):

1. **Nix with nix-darwin** - Manages Homebrew packages declaratively

   - All dependencies (Powerlevel10k, zsh plugins, tools, fonts, etc.) are installed via darwin.nix

2. **GNU Stow** - Symlink manager (installed via nix-darwin)
   ```bash
   # Already in darwin.nix brews list
   ```

### Option B: Manual Installation

If not using nix-darwin:

1. **Homebrew** - macOS package manager

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **GNU Stow**

   ```bash
   brew install stow
   ```

3. **Zsh plugins and tools**

   ```bash
   brew install powerlevel10k zsh-autosuggestions zsh-syntax-highlighting
   brew install bat eza fzf direnv tmux
   ```

4. **Fonts**
   ```bash
   brew install --cask font-meslo-lg-nerd-font
   ```

## Installation

### Fresh System Installation

From this repository's root directory:

```bash
stow . --dotfiles --target $HOME
```

This will symlink all dotfiles to your home directory.

**Note**: GPG config files require an additional manual step:

```bash
ln -s ~/code/dotfiles/dot-gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf
```

### Initial Migration (Existing Dotfiles)

If you're setting up this repo for the first time and want to migrate existing dotfiles:

```bash
stow . --adopt --dotfiles --target $HOME
```

The `--adopt` flag will move any existing files in your home directory into the dotfiles repo. After adoption, review the changes and commit only the files you want to manage.

**Warning**: Be careful with `--adopt` as it will move existing files into the repo. Review changes before committing.

## Structure

```
dotfiles/
├── dot-config/          # XDG config directory (~/.config/)
│   ├── alacritty/       # Terminal emulator
│   └── nvim/            # Neovim configuration (Lazy.nvim)
├── dot-gnupg/           # GPG configuration (~/.gnupg/)
│   └── gpg-agent.conf   # GPG agent settings
├── dot-gitconfig        # Git configuration (~/.gitconfig)
├── dot-gitconfig.local  # Git signing key (~/.gitconfig.local, not tracked)
├── dot-zshrc            # Zsh shell (~/.zshrc)
├── dot-tmux.conf        # Tmux terminal multiplexer (~/.tmux.conf)
├── dot-p10k.zsh         # Powerlevel10k theme (~/.p10k.zsh)
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
- Signing key stored in `~/.gitconfig.local` (not tracked in git)

### GPG

- GPG agent configuration for password caching
- pinentry-mac for GUI password prompts
- Cache TTL settings (10 min default, 2 hour max)

### Tools

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
stow -D . --dotfiles --target $HOME
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
- **GPG config files require manual symlinking**: Since `~/.gnupg/` contains sensitive unmanaged files (private keys, trustdb, sockets), stow cannot symlink the entire directory. Individual config files must be manually symlinked after running stow.
- **No Brewfile needed**: Dependencies are managed declaratively via [mac-nix-configs](https://github.com/bryan-thompsoncodes/mac-nix-configs) darwin.nix
