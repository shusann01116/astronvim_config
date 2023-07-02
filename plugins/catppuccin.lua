return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup {
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dap = {
          enabled = true,
          enable_ui = true,
        },
        gitsigns = true,
        leap = true,
        markdown = true,
        mason = true,
        mini = true,
        neotree = true,
        notify = true,
        treesitter = true,
        telescope = true,
      },
    }
  end,
}
