return {
  {
    'neovim/nvim-lspconfig',
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      -- Register OpenAPI filetypes for vacuum LSP (not detected automatically)
      vim.filetype.add({
        pattern = {
          ['openapi.*%.ya?ml'] = 'yaml.openapi',
          ['openapi.*%.json'] = 'json.openapi',
        },
      })

      vim.lsp.config('*', {
        capabilities = vim.lsp.protocol.make_client_capabilities(),
        root_markers = { '.git' },
      })

      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            runtime = { version = 'LuaJIT' },
            diagnostics = { globals = { 'vim' } },
            workspace = { library = { vim.env.VIMRUNTIME } },
          },
        },
      })

      vim.lsp.config('solargraph', {
        settings = {
          solargraph = { diagnostics = true, formatting = true },
        },
      })

      vim.lsp.enable({
        'pyright',
        'ts_ls',
        'lua_ls',
        'nixd',
        'solargraph',
        'yamlls',
        'tsp_server',
        'vacuum',
        'graphql',
      })

      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
      vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Diagnostic float' })
      vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics list' })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(args)
          local buf = args.buf
          local opts = { buffer = buf }

          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)
        end,
      })
    end,
  },
}
