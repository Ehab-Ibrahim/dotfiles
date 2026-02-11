return function(input_line_number, cursor_line, cursor_column)
  vim.opt.termguicolors = true
  vim.opt.laststatus = 0
  vim.opt.clipboard = "unnamedplus"
  vim.opt.modifiable = false
  vim.opt.ignorecase = true
  vim.opt.smartcase = true
  vim.opt.cmdheight = 0

  -- Make background and foreground inherit from terminal
  vim.cmd("highlight Normal guibg=NONE guifg=NONE ctermbg=NONE ctermfg=NONE")

  vim.keymap.set("n", "q", ":qa!<CR>", { silent = true })

  for _, k in ipairs({ "i", "a", "I", "A", "o", "O", "s", "S", "R" }) do
    vim.keymap.set("n", k, "<Nop>")
  end

  vim.api.nvim_create_autocmd("VimEnter", {
    pattern = "*",
    callback = function()
      local s = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local b = vim.api.nvim_create_buf(false, true)
      local c = vim.api.nvim_open_term(b, {})
      vim.api.nvim_chan_send(c, table.concat(s, string.char(10)))
      vim.api.nvim_set_current_buf(b)
      vim.api.nvim_buf_delete(1, { force = true })
      vim.defer_fn(function()
        local row = math.max(1, input_line_number + cursor_line - 1)
        local col = cursor_column
        vim.cmd("normal! " .. row .. "G" .. col .. "|")
      end, 10)
    end,
  })
end
