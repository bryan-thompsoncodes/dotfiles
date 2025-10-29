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

## VA Development Setup

For VA.gov development, use the included setup script to clone repositories:

```bash
./setup-va-repos.sh
```

This interactive script will:

- Check which VA repositories already exist
- Display a summary of what needs to be cloned
- Ask for confirmation before proceeding
- Clone missing repositories to `~/code/department-of-veterans-affairs/`
- Show progress and final summary

**Prerequisites:**

- SSH keys must be configured and added to your GitHub account
- Test your GitHub connection: `ssh -T git@github.com`

**Repositories cloned:**

- `vets-website` - Frontend application
- `next-build` - Next.js build
- `vets-api` - Rails API backend
- `component-library` - Shared component library
- `va.gov-cms` - Drupal CMS

After setup completes, you can launch the full development environment with `va-tmux`.

## Structure

```text
dotfiles/
├── dot-config/          # XDG config directory (~/.config/)
│   ├── alacritty/       # Terminal emulator
│   └── nvim/            # Neovim configuration (Lazy.nvim)
├── dot-gnupg/           # GPG configuration (~/.gnupg/)
│   └── gpg-agent.conf   # GPG agent settings
├── dot-tmux/            # Tmux session templates (~/.tmux/)
│   └── va-dev-session.sh  # VA development session
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

### Tmux Session Templates

Pre-configured tmux sessions for common development workflows.

#### VA Development Session

Launch a complete VA development environment with one command:

```bash
~/.tmux/va-dev-session.sh
```

Or simply use the alias:

```bash
va-tmux
```

This creates a tmux session named `va-dev` with 5 windows:

**Windows 1-4** (split panes):

- **Left pane**: Empty terminal in the repo directory
- **Right pane**: Server start command pre-populated (press Enter to execute, selected by default)

**Window 5** (single pane):

- Single terminal with CMS startup command

**Window layout:**

1. `vets-website` - Frontend application (`vets-website-server`)
2. `next-build` - Next.js build (`yarn dev`)
3. `vets-api` - Rails API (`vets-api-server`)
4. `component-library` - Component library storybook (`cl-storybook`)
5. `va.gov-cms` - CMS environment (`ddev start && ddev status`)

If the session already exists, the script will attach to it instead of creating a new one.

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
