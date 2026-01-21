-- Define a function that closes Snacks explorer picker
local function hide_snacks()
  local explorers = Snacks.picker.get({ source = "explorer" })
  for _, p in ipairs(explorers) do
    p:close()
  end
  local terminals = Snacks.terminal.list()
  for _, p in ipairs(terminals) do
    p:hide()
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      require("dap").listeners.after.event_initialized["hide_snacks"] = hide_snacks
    end,
  },
  {
    "rcarriga/nvim-dap-ui",

    opts = {
      element_mappings = {
        stacks = { open = { "<CR>", "o", "e" } },
        breakpoints = { open = { "<CR>", "o", "e" } },
      },
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.5 },
            { id = "watches", size = 0.2 },
            { id = "stacks", size = 0.15 },
            { id = "breakpoints", size = 0.15 },
          },
          position = "left",
          size = 40,
        },
        {
          elements = {
            { id = "repl", size = 0.6 },
            { id = "console", size = 0.4 },
          },
          position = "bottom",
          size = 13,
        },
      },
    },
    keys = {
      {
        "<leader>dE",
        function()
          vim.ui.input({ prompt = "DAP Eval: " }, function(input)
            if input == "" then
              input = nil
            end
            require("dapui").eval(input, { enter = true })
          end)
        end,
        desc = "DAP Eval (input)",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval(nil, { enter = true })
        end,
        desc = "DAP Eval",
      },
      {
        "<leader>dU",
        function()
          -- Need to run reset twice to fully reset UI for some reason
          hide_snacks()
          require("dapui").open({ reset = true })
          require("dapui").open({ reset = true })
        end,
        desc = "DAP UI (reset)",
      },
      {
        "<leader>du",
        function()
          -- Need to run reset twice to fully reset UI for some reason
          hide_snacks()
          require("dapui").toggle()
        end,
        desc = "DAP UI",
      },
      {
        "<leader>e",
        function()
          require("dapui").close()
          Snacks.explorer()
        end,
        desc = "Explorer Snacks (cwd)",
      },
      {
        "<leader>E",
        function()
          require("dapui").close()
          Snacks.explorer({ cwd = LazyVim.root() })
        end,
        desc = "Explorer Snacks (Root Dir)",
      },
      {
        "<c-/>",
        mode = { "n", "t" },
        function()
          require("dapui").close()
          Snacks.terminal(nil, { cwd = LazyVim.root() })
        end,
        desc = "Terminal (Root Dir)",
      },
      {
        "<leader>ft",
        function()
          require("dapui").close()
          Snacks.terminal(nil, { cwd = LazyVim.root() })
        end,
        desc = "Terminal (Root Dir)",
      },
      {
        "<leader>fT",
        function()
          require("dapui").close()
          Snacks.terminal()
        end,
        desc = "Terminal (Root Dir)",
      },
    },
  },
}
