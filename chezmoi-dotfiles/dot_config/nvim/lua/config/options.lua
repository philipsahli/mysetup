-- lua/config/options.lua — Editor options for Go
-- Managed by chezmoi

local opt = vim.opt

-- Go uses tabs
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = false

-- UI
opt.relativenumber = true
opt.number = true
opt.scrolloff = 10
opt.signcolumn = "yes"
opt.cursorline = true
opt.wrap = false

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Persistence
opt.undofile = true
opt.undolevels = 10000

-- Performance
opt.updatetime = 200
opt.timeoutlen = 300

-- System clipboard
opt.clipboard = "unnamedplus"
