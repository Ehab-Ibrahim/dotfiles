-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
return {
  vim.keymap.set("i", "jk", "<esc>"),
  vim.keymap.set("i", "kj", "<esc>"),
  vim.keymap.set("t", "<c-n><c-n>", "<c-\\><c-n>"),
  vim.keymap.set("n", "<leader>ff", LazyVim.pick("files", { root = false }), { desc = "Find Files (cwd)" }),
  vim.keymap.set("n", "<leader>fF", LazyVim.pick("files"), { desc = "Find Files (Root Dir)" }),
  vim.keymap.set("n", "<leader>gg", function() Snacks.lazygit() end, { desc = "Lazygit (cwd)" }),
  vim.keymap.set("n", "<leader>gG", function() Snacks.lazygit( { cwd = LazyVim.root.git() }) end, { desc = "Lazygit (Root Dir)" }),
  vim.keymap.set("n", "<leader>e", function() Snacks.explorer() end, { desc = "Explorer Snacks (cwd)" }),
  vim.keymap.set("n", "<leader>E", function() Snacks.explorer({ cwd = LazyVim.root() }) end, { desc = "Explorer Snacks (Root Dir)" }),
}
