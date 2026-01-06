local opt = vim.opt

-- line numbers
opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- line wrapping
opt.wrap = false

-- search setting
opt.ignorecase = true
opt.smartcase = true

-- cursor line
opt.cursorline = true

-- appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

-- backspace
opt.backspace = "indent,eol,start"

-- clipboard
opt.clipboard:append("unnamedplus")

-- split windows
opt.splitright = true
opt.splitbelow = true

opt.iskeyword:append("-")

-- undo/backup
opt.undofile = true              -- persistent undo
opt.undodir = vim.fn.stdpath("data") .. "/undo"
opt.swapfile = false             -- disable swap files (use undo instead)
opt.backup = false               -- disable backup files
opt.writebackup = false          -- don't backup before overwriting

-- scrolling
opt.scrolloff = 8                -- keep 8 lines visible when scrolling
opt.sidescrolloff = 8            -- same for horizontal scrolling

-- command mode
opt.inccommand = "split"         -- preview substitutions in split

-- completion
opt.completeopt = "menu,menuone,noselect"  -- better completion behavior

-- timing
opt.timeoutlen = 300             -- faster key sequence timeout
opt.updatetime = 250             -- faster CursorHold events
