return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status") -- to configure lazy pending updates count

    -- Use shared color scheme
    local colors = require("bryan.core.colors")

    local my_lualine_theme = {
      normal = {
        a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg_alt, fg = colors.fg },
        c = { bg = colors.bg_alt, fg = colors.fg },
      },
      insert = {
        a = { bg = colors.green, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg_alt, fg = colors.fg },
        c = { bg = colors.bg_alt, fg = colors.fg },
      },
      visual = {
        a = { bg = colors.violet, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg_alt, fg = colors.fg },
        c = { bg = colors.bg_alt, fg = colors.fg },
      },
      command = {
        a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg_alt, fg = colors.fg },
        c = { bg = colors.bg_alt, fg = colors.fg },
      },
      replace = {
        a = { bg = colors.red, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg_alt, fg = colors.fg },
        c = { bg = colors.bg_alt, fg = colors.fg },
      },
      inactive = {
        a = { bg = colors.bg_inactive, fg = colors.fg_alt, gui = "bold" },
        b = { bg = colors.bg_inactive, fg = colors.fg_alt },
        c = { bg = colors.bg_inactive, fg = colors.fg_alt },
      },
    }

    -- configure lualine with modified theme
    lualine.setup({
      options = {
        theme = my_lualine_theme,
      },
      sections = {
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = { fg = colors.orange },
          },
          { "encoding" },
          { "fileformat" },
          { "filetype" },
        },
      },
    })
  end,
}
