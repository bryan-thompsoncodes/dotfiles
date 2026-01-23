# Zsh options and keybindings

# Zsh options
setopt AUTO_CD  # Type directory name to cd into it (e.g., just type '..' or '/tmp')

# Enable vi mode
bindkey -v

# Enhanced completion settings
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case insensitive completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completion
