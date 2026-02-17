-- lua/plugins/go.lua — Go development for LazyVim
-- Managed by chezmoi — edit via: chezmoi edit ~/.config/nvim/lua/plugins/go.lua

return {
  -- LazyVim Go extras (gopls, gofumpt, goimports, etc.)
  { import = "lazyvim.plugins.extras.lang.go" },

  -- DAP (debugger) for delve
  { import = "lazyvim.plugins.extras.dap.core" },

  -- Seamless Ctrl-h/j/k/l between tmux + nvim
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>" },
    },
  },

  -- Go code generation (struct tags, if err, interface impl, tests)
  {
    "olexsmir/gopher.nvim",
    ft = "go",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    config = function() require("gopher").setup() end,
    keys = {
      { "<leader>cgt", "<cmd>GoTagAdd json<cr>",  desc = "Add json tags",     ft = "go" },
      { "<leader>cgT", "<cmd>GoTagRm json<cr>",   desc = "Remove json tags",  ft = "go" },
      { "<leader>cge", "<cmd>GoIfErr<cr>",         desc = "Generate if err",   ft = "go" },
      { "<leader>cgi", "<cmd>GoImpl<cr>",          desc = "Implement iface",   ft = "go" },
      { "<leader>cga", "<cmd>GoTestAdd<cr>",       desc = "Add test for func", ft = "go" },
      { "<leader>cgA", "<cmd>GoTestsAll<cr>",      desc = "Add all tests",     ft = "go" },
    },
  },

  -- Neotest with Go adapter
  {
    "nvim-neotest/neotest",
    dependencies = { "fredrikaverpil/neotest-golang" },
    opts = {
      adapters = {
        ["neotest-golang"] = {
          go_test_args = { "-v", "-race", "-count=1" },
          dap_go_enabled = true,
        },
      },
    },
  },

  -- gopls fine-tuning
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              usePlaceholders = true,
              analyses = {
                unusedparams = true,
                shadow = true,
                nilness = true,
                unusedwrite = true,
                useany = true,
              },
              staticcheck = true,
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },
      },
    },
  },

  -- Format on save
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt" },
      },
    },
  },

  -- Linting
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        go = { "golangcilint" },
      },
    },
  },
}
