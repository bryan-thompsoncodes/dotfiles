# Aliases
# Portable aliases live in dot-config/shell/aliases.sh, shared with bash on
# Omarchy hosts. This file loads them and adds what only the fully-owned
# zsh machines (macOS/NixOS) should have.

# Resolve the shared file relative to this (possibly symlinked) file, so it
# works before and after stow deploys ~/.config/shell.
_shared_aliases="${${(%):-%N}:A:h}/../shell/aliases.sh"
[[ -f "$_shared_aliases" ]] || _shared_aliases="${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliases.sh"
[[ -f "$_shared_aliases" ]] && source "$_shared_aliases"
unset _shared_aliases

# eza ls-family — personal flavors for machines this repo fully owns.
# (Deliberately not shared: Omarchy ships its own eza aliases and keeps them.)
alias ls="eza --icons"
alias ll="eza -lah --icons"
alias la="eza -a --icons"
alias lla="eza -la"
alias lsa="eza -lah"
alias lt="eza --tree --icons"

# Nix flake update alias
alias nix-flake-update="nix flake update --flake $HOME/code/nix-configs"

# Nix rebuild aliases
alias update-mbp="sudo darwin-rebuild switch --flake ~/code/nix-configs/#mbp"
alias update-a6mbp="sudo darwin-rebuild switch --flake ~/code/nix-configs/#a6mbp"
alias update-studio="sudo darwin-rebuild switch --flake ~/code/nix-configs/#studio"
alias update-gnarbox="sudo nixos-rebuild switch --flake ~/code/nix-configs/#gnarbox"
alias update-inix="sudo darwin-rebuild switch --flake ~/code/nix-configs/#inix"

# Nix upgrade aliases (update flake.lock first, then rebuild)
alias upgrade-mbp="nix-flake-update && update-mbp"
alias upgrade-a6mbp="nix-flake-update && update-a6mbp"
alias upgrade-studio="nix-flake-update && update-studio"
alias upgrade-gnarbox="nix-flake-update && update-gnarbox"
alias upgrade-inix="nix-flake-update && update-inix"

# Use macOS system SSH for UseKeyChain support (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias ssh='/usr/bin/ssh'
fi
