-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd({ "FileType" }, {
  group = vim.api.nvim_create_augroup("verilog_comment", { clear = true }),
  pattern = { "verilog", "systemverilog" },
  callback = function()
    vim.opt_local.commentstring = "// %s"
  end,
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = vim.api.nvim_create_augroup("markdown_ruler", { clear = true }),
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.colorcolumn = "80"
  end,
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = vim.api.nvim_create_augroup("verilog_pair_disable", { clear = true }),
  pattern = { "verilog", "systemverilog" },
  callback = function()
    MiniPairs = require("mini.pairs")
    MiniPairs.unmap("i", "'", "''")
    MiniPairs.unmap("i", "`", "``")
  end,
})
-- Add org parser for treesitter
vim.api.nvim_create_autocmd("User", {
  pattern = "TSUpdate",
  callback = function()
    require("nvim-treesitter.parsers").org = {
      tier = 1,
      install_info = {
        url = "https://github.com/milisims/tree-sitter-org",
        revision = "main",
        files = { "src/parser.c", "src/scanner.c" },
      },
      filetype = "org",
    }
  end,
})
