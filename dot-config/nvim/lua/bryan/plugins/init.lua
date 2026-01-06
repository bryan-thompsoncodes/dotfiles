-- Plugin specifications for Lazy.nvim
-- Explicit plugin list ensures clear load order and dependency management
return {
  require("bryan.plugins.bufferline"),
  require("bryan.plugins.colorscheme"),
  require("bryan.plugins.comment"),
  require("bryan.plugins.lualine"),
  require("bryan.plugins.nvim-tree"),
  require("bryan.plugins.opencode"),
  require("bryan.plugins.telescope"),
  require("bryan.plugins.vim-be-good"),
  require("bryan.plugins.vim-maximizer"),
  require("bryan.plugins.vim-tmux-navigator"),
  require("bryan.plugins.which-key"),
}
