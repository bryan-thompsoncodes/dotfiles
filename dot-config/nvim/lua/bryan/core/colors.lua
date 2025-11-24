-- Nightfly color palette
-- Centralized color definitions for consistent theming across all plugins
-- To change the theme, update these values and reload nvim

local colors = {
  -- Background colors
  bg = "#011627",           -- Main background (nightfly dark blue)
  bg_alt = "#112638",       -- Alternative background (lighter blue)
  bg_inactive = "#2c3043",  -- Inactive elements

  -- Foreground colors
  fg = "#c3ccdc",           -- Main foreground text
  fg_alt = "#b3b9c5",       -- Alternative/dimmed text

  -- Accent colors
  blue = "#65D1FF",         -- Primary accent (bright blue)
  green = "#3EFFDC",        -- Success/insert mode
  violet = "#FF61EF",       -- Visual mode
  yellow = "#FFDA7B",       -- Warning/command mode
  red = "#FF4A4A",          -- Error/replace mode
  orange = "#ff9e64",       -- Secondary accent
  cyan = "#3FC5FF",         -- Tertiary accent

  -- UI element colors
  border = "#2c3043",       -- Borders and separators
  border_active = "#65D1FF", -- Active borders
}

return colors
