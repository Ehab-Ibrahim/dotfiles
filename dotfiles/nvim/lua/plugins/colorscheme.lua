return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },
  {
    "sainnhe/everforest",
    lazy = false,
    priority = 1000,
  },
  {
    "AlexvZyl/nordic.nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "rose-pine/neovim",
    lazy = false,
    priority = 1000,
    name = "rose-pine",
    opts = {
      -- variant = "moon",
      styles = {
        italic = false,
      },
    },
  },
  {
    "sainnhe/sonokai",
    lazy = false,
    priority = 1000,
    config = function()
      -- Optionally configure and load the colorscheme
      -- directly inside the plugin declaration.
      vim.g.sonokai_style = "maia"
    end,
  },
  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = {
      background = {
        light = "latte",
        dark = "macchiato",
      },
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
  },
  {
    {
      "LazyVim/LazyVim",
      opts = {
        colorscheme = "catppuccin-macchiato",
      },
    },
  },
}
