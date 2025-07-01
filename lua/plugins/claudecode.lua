---@type LazySpec
return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim", "AstroNvim/astrocore" },
  config = true,
  specs = {
    {
      "AstroNvim/astrocore",
      opts = {
        mappings = {
          n = {
            ["<leader>a"] = { desc = "AI/Claude Code" },
            ["<leader>ac"] = { "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
            ["<leader>af"] = { "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
            ["<leader>ar"] = { "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
            ["<leader>aC"] = { "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
            ["<leader>ab"] = { "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
            ["<leader>aa"] = { "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
            ["<leader>ad"] = { "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
          },
          v = {
            ["<leader>a"] = { desc = "AI/Claude Code" },
            ["<leader>as"] = { "<cmd>ClaudeCodeSend<cr>", desc = "Send to Claude" },
          },
        },
        autocmds = {
          claudecode_mappings = {
            {
              event = "FileType",
              pattern = { "NvimTree", "neo-tree", "oil" },
              callback = function()
                vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", {
                  desc = "Add file",
                  buffer = true,
                })
              end,
            },
          },
        },
      },
    },
  },
}
