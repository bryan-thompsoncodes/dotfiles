# Dotfiles

Personal development environment configuration, managed with GNU Stow.

Cross-platform compatible with macOS and NixOS.

## Overview

This repository contains dotfiles organized into Stow packages for easy symlinking and management. Configurations are split between:

- `~/` (home directory) for traditional dotfiles
- `~/.config/` for XDG-compliant applications

## Prerequisites

### Required

- **GNU Stow** - Symlink manager for dotfiles

### Platform-Specific Setup

#### macOS

**Option A: Using Nix-Darwin (Recommended)**

If you're using [nix-configs](https://github.com/bryan-thompsoncodes/nix-configs):

- All dependencies (Powerlevel10k, zsh plugins, tools, fonts, etc.) are installed via nix-darwin configuration
- GNU Stow is included in the nix configuration

**Option B: Using Homebrew**

1. Install Homebrew:

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Install dependencies:
   ```bash
   brew install stow
   brew install powerlevel10k zsh-autosuggestions zsh-syntax-highlighting
   brew install bat eza fzf direnv tmux tpm
   brew install neovim git gnupg
   brew install --cask font-meslo-lg-nerd-font
   ```

#### NixOS

**Option A: Using Nix Flakes (Recommended)**

If you're using [nix-configs](https://github.com/bryan-thompsoncodes/nix-configs):

- All dependencies (Powerlevel10k, zsh plugins, tools, fonts, etc.) are installed via NixOS configuration
- GNU Stow is included in the nix configuration

**Option B: Manual System Configuration**

Add the following packages to your `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  stow
  zsh-powerlevel10k
  zsh-autosuggestions
  zsh-syntax-highlighting
  bat
  eza
  fzf
  direnv
  tmux
  tmuxPlugins.tpm
  (nerdfonts.override { fonts = [ "Meslo" ]; })
  neovim
  git
  gnupg
  pinentry-curses  # or pinentry-gnome3, pinentry-qt
];
```

**Note:** Some configurations may need local overrides:

- `~/.gnupg/gpg-agent.conf` - Set correct pinentry program path for your system

## Installation

### Fresh System Installation

From this repository's root directory:

```bash
stow . --dotfiles --target $HOME
./setup-platform-configs.sh
```

This will symlink all dotfiles to your home directory, configure platform-specific overrides (Alacritty), install tmux plugins, and set up the secrets directory (populating the OpenCode API key from Keychain on macOS).

**Additional Manual Step:**

**GPG configuration** - Link GPG agent config:

```bash
ln -s ~/code/dotfiles/dot-gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf
```

If tmux is already running, reload the config to apply the newly installed plugins:

```bash
tmux source-file ~/.tmux.conf
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
│   ├── direnv/          # Direnv configuration with nix-direnv
│   ├── goose/           # Goose AI agent configuration
│   │   ├── config.yaml      # Extension and model settings
│   │   ├── permission.yaml  # Tool permissions
│   │   └── goosehints       # Project-specific AI guidance
│   ├── nvim/            # Neovim configuration (Lazy.nvim)
│   └── opencode/        # OpenCode AI assistant
│       └── opencode.json    # Provider config (uses {file:...} for API key)
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

- **direnv**: Automatic environment switching with nix-direnv for fast Nix shell caching
- **tmux**: Terminal multiplexer with vim keybindings

### AI / OpenCode

- Config lives in `dot-config/opencode/opencode.json` (tracked, stowed to `~/.config/opencode/`)
- API key is stored in `~/.secrets/opencode-api-key` (outside repo, never tracked)
- Config uses `{file:~/.secrets/opencode-api-key}` reference for safe stowing
- `setup-platform-configs.sh` creates `~/.secrets/` and populates the key from Keychain (macOS)
- On macOS, store your API key in Keychain:
  `security add-generic-password -a "$LOGNAME" -s ai.thompson.codes-openwebui -w '<api-key>'`
- On Linux, manually create `~/.secrets/opencode-api-key` with your API key
- For repo-specific tweaks (extra docs, different permissions, etc.), create `.opencode/project.json` inside the repo

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

## Cross-Platform Compatibility

These dotfiles are designed to work on both macOS and NixOS with minimal platform-specific configuration.

### How It Works

**Shell configurations** (`dot-zshrc`, `dot-tmux.conf`) use a "source if exists" pattern that checks multiple paths:

- macOS (Homebrew): `/opt/homebrew/share/...`
- NixOS (system): `/run/current-system/sw/share/...`
- Linux (standard): `/usr/share/...`

### Platform-Specific Settings

Some settings require platform-specific handling:

1. **SSH Keychain (macOS only)** - `dot-zshrc` conditionally aliases SSH to use macOS keychain support
2. **GPG Pinentry** - `dot-gnupg/gpg-agent.conf` defaults to macOS pinentry-mac; NixOS users should override locally
3. **Alacritty Window Decorations** - `setup-platform-configs.sh` automatically configures:
   - macOS: No decorations (clean look, no traffic lights)
   - Linux: Buttonless decorations (title bar for window management)

### NixOS-Specific Notes

On NixOS, you may want to create local overrides for:

```bash
# Override GPG pinentry for NixOS
echo "pinentry-program /run/current-system/sw/bin/pinentry-curses" > ~/.gnupg/gpg-agent.conf.local
```

Or manage these via your NixOS system configuration.

## Related Repositories

- [nix-configs](https://git.snowboardtechie.com/bryan/nix-configs) - Nix system configuration for both macOS and NixOS
  - macOS: nix-darwin with declarative Homebrew package management
  - NixOS: System configuration with flakes
  - Development environment shells (vets-api, vets-website, etc.)
  - System settings and package management

### 3 gits, one repo

This repository syncs to multiple remotes. The primary repository is at [git.snowboardtechie.com](https://git.snowboardtechie.com/bryan/dotfiles), with backups on [Codeberg](https://codeberg.org/SnowboardTechie/dotfiles) and [GitHub](https://github.com/bryan-thompsoncodes/dotfiles).

## Notes

- Stow uses relative symlinks by default
- The `--dotfiles` flag converts `dot-` prefix to `.` for files/folders
- ZSA keyboard layouts are stored but not symlinked
- **AGENTS.md is ignored by Stow** via `.stow-local-ignore` to prevent symlinking documentation to the home directory
- **Repository files are ignored**: `.git`, `README.md`, `.gitignore`, and `.stow-local-ignore` are excluded via `.stow-local-ignore` to prevent symlinking repository metadata
- **GPG config files require manual symlinking**: Since `~/.gnupg/` contains sensitive unmanaged files (private keys, trustdb, sockets), stow cannot symlink the entire directory. Individual config files must be manually symlinked after running stow.
- **Package management**: Dependencies managed via [nix-configs](https://github.com/bryan-thompsoncodes/nix-configs) for both macOS (nix-darwin) and NixOS (system configuration), or manually via Homebrew on macOS
