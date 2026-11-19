return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "org",
        "python",
        "regex",
        "systemverilog",
        "vim",
        "yaml",
      },
    },
  },

  {
    "linux-cultist/venv-selector.nvim",
    branch = "main",
  },

  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        nix = { "alejandra" },
        verilog = { "verible" },
        systemverilog = { "verible" },
      },
      formatters = {
        -- slang-server doesn't format
        verible = {
          prepend_args = {
            "--wrap_spaces=2",
            "--column_limit=100",
            "--port_declarations_alignment=align",
            "--named_parameter_alignment=align",
            "--named_port_alignment=align",
            "--try_wrap_long_lines",
          },
        },
      },
    },
  },

  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "mason-org/mason.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },

  {
    "neovim/nvim-lspconfig",
    opts = {
      -- options for vim.diagnostic.config()
      diagnostics = {
        virtual_text = false,
      },
      servers = {
        tombi = {},
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
                inlayHints = {
                  variableTypes = false,
                  callArgumentNames = false,
                  functionReturnTypes = false,
                },
              },
            },
          },
        },
        -- Per-project settings (include dirs, a .f file list) go in .slang/server.json
        slang_server = {},
        verible = {
          -- instance-shadowing flags every `import pkg::item;` after the first as shadowing `pkg`
          cmd = { "verible-verilog-ls", "--ruleset", "all", "--rules=-instance-shadowing" },
          on_attach = function(client, bufnr)
            -- Workaround for fixing double diagnostics for Verible
            -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_pullDiagnostics
            client.server_capabilities.diagnosticProvider = nil
            -- Disable <go to definition> for Verible - Rely on slang-server for that
            -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
            client.server_capabilities.definitionProvider = false
            -- Disable formatting - conform.nvim runs verible-verilog-format instead
            -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_formatting
            client.server_capabilities.documentFormattingProvider = false
          end,
        },
      },
    },
  },
}
