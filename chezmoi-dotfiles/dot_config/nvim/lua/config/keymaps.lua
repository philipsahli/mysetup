-- lua/config/keymaps.lua — Go + Claude Code keymaps
-- Managed by chezmoi

local map = vim.keymap.set

-- Exit insert mode
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Move lines in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Centered scrolling and searching
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Quick save
map("n", "<C-s>", "<cmd>w<cr>")
map("i", "<C-s>", "<Esc><cmd>w<cr>")

-- Go: toggle between foo.go ↔ foo_test.go
map("n", "<leader>ct", function()
  local file = vim.fn.expand("%")
  if file:match("_test%.go$") then
    vim.cmd("edit " .. file:gsub("_test%.go$", ".go"))
  else
    vim.cmd("edit " .. file:gsub("%.go$", "_test.go"))
  end
end, { desc = "Toggle test file" })

-- Go: run test under cursor
map("n", "<leader>rt", function()
  vim.cmd("!go test -v -run " .. vim.fn.expand("<cword>") .. " ./...")
end, { desc = "Run test under cursor" })

-- Go: run all tests
map("n", "<leader>rT", "<cmd>!go test -v -race ./...<cr>", { desc = "Run all tests" })

-- Go: run current file
map("n", "<leader>rr", "<cmd>!go run %<cr>", { desc = "Go run current file" })

-- Terminal
map("n", "<leader>tt", function()
  vim.cmd("botright 15split | terminal")
end, { desc = "Terminal (bottom)" })

map("n", "<leader>tc", function()
  vim.cmd("botright 15split | terminal claude")
end, { desc = "Claude Code" })

-- Easy exit from terminal
map("t", "<Esc><Esc>", "<C-\\><C-n>")
map("t", "jk", "<C-\\><C-n>")
