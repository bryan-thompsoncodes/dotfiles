return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'master',
  build = ':TSUpdate',
  event = { 'BufReadPre', 'BufNewFile' },
  main = 'nvim-treesitter.configs',
  opts = {
    ensure_installed = {
      'lua', 'vim', 'vimdoc',
      'javascript', 'typescript', 'tsx',
      'python', 'ruby',
      'html', 'css', 'scss',
      'json', 'yaml', 'toml',
      'bash', 'nix',
      'markdown', 'markdown_inline',
      'gitcommit', 'diff',
    },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<C-space>',
        node_incremental = '<C-space>',
        scope_incremental = false,
        node_decremental = '<bs>',
      },
    },
  },
}
