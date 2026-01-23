# Aliases
# Organized by category for easy maintenance

# Modern tool replacements
alias cat="bat"
alias ls="eza --icons"
alias ll="eza -lah --icons"
alias la="eza -a --icons"
alias lla="eza -la"
alias lsa="eza -lah"
alias lt="eza --tree --icons"
alias vim="nvim"
alias vi="nvim"

# Utility aliases
alias clr="clear"
alias fman="compgen -c | fzf | xargs man"
alias va-tmux="~/.tmux/va-server-stack.sh"

# Git aliases
alias ga="git add"
alias gb="git branch"
alias gd="git diff"
alias gs="git status"
alias gst="git status"
alias gp="git push"
alias gl="git log --oneline --graph"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gaa="git add --all"
alias gcm="git commit -m"
alias gbd="git branch -d"
alias gbD="git branch -D"
alias gpl="git pull"
alias gpF="git push --force"

# Nix flake update alias
alias nix-flake-update="nix flake update --flake $HOME/code/nix-configs"

# Nix rebuild aliases
alias update-mbp="sudo darwin-rebuild switch --flake ~/code/nix-configs/#mbp"
alias update-a6mbp="sudo darwin-rebuild switch --flake ~/code/nix-configs/#a6mbp"
alias update-studio="sudo darwin-rebuild switch --flake ~/code/nix-configs/#studio"
alias update-gnarbox="sudo nixos-rebuild switch --flake ~/code/nix-configs/#gnarbox"

# Nix upgrade aliases (update flake.lock first, then rebuild)
alias upgrade-mbp="nix-flake-update && update-mbp"
alias upgrade-a6mbp="nix-flake-update && update-a6mbp"
alias upgrade-studio="nix-flake-update && update-studio"
alias upgrade-gnarbox="nix-flake-update && update-gnarbox"

# Navigation aliases
alias dotfiles="cd ~/code/dotfiles"
alias nix-configs="cd ~/code/nix-configs"

# Use macOS system SSH for UseKeyChain support (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias ssh='/usr/bin/ssh'
fi
