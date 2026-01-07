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
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      -- options for vim.diagnostic.config()
      diagnostics = {
        virtual_text = false,
      },
      servers = {
        clangd = { mason = false },
        ruff = { mason = false },
        pyright = { mason = false },
        nil_ls = { mason = false },
        basedpyright = {
          mason = false,
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
        svlangserver = {
          mason = false,
          settings = {
            systemverilog = {
              launchConfiguration = "verilator -sv -Wall --lint-only --timing",
              -- In lua, \z escape character is used to ignore all whitespace
              -- until the next non-whitespace character
              formatCommand = "verible-verilog-format \z
                --wrap_spaces 2 \z
                --column_limit 100 \z
                --port_declarations_alignment align \z
                --named_parameter_alignment align \z
                --named_port_alignment align \z
                --try_wrap_long_lines \z
              ",
            },
          },
        },
        verible = {
          cmd = { "verible-verilog-ls", "--ruleset", "all" },
          mason = false,
          on_attach = function(client, bufnr)
            -- Workaround for fixing double diagnostics for Verible
            -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_pullDiagnostics
            client.server_capabilities.diagnosticProvider = nil
            -- Disable <go to definition> for Verible - Rely on SVlangserver for that
            -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_definition
            client.server_capabilities.definitionProvider = false
            -- Disable formatting - Rely on SVlangserver for that
            -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_formatting
            client.server_capabilities.documentFormattingProvider = false
          end,
        },
      },
    },
  },
}
