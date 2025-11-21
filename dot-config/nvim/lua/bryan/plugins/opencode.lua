return {
  'NickvanDyke/opencode.nvim',
  dependencies = {
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    vim.g.opencode_opts = {
      -- Your configuration here if needed
    }

    -- Required for auto_reload
    vim.o.autoread = true

    -- Keymaps (prefixed to avoid clobbering core motions)
    local map = vim.keymap.set
    local opencode_prefix = "<leader>o"

    map({ "n", "x" }, opencode_prefix .. "a", function()
      require("opencode").ask("@this: ", { submit = true })
    end, { desc = "Opencode ask (selection)" })

    map({ "n", "x" }, opencode_prefix .. "x", function()
      require("opencode").select()
    end, { desc = "Opencode actions" })

    map({ "n", "x" }, opencode_prefix .. "g", function()
      require("opencode").prompt("@this")
    end, { desc = "Opencode add context" })

    map("n", opencode_prefix .. "t", function()
      require("opencode").toggle()
    end, { desc = "Opencode toggle panel" })

    map("n", "<S-C-u>", function()
      require("opencode").command("messages_half_page_up")
    end, { desc = "Opencode messages page up" })

    map("n", "<S-C-d>", function()
      require("opencode").command("messages_half_page_down")
    end, { desc = "Opencode messages page down" })
  end,
}