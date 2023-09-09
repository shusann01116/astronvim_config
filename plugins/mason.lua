local lspconfigs = {
  "lua_ls",
  "gopls",
  "taplo",
  "omnisharp",
  "yamlls",
  "dockerls",
  "bashls",
  "gopls",
  "jsonls",
  "marksman",
  "pyright",
  "ruff_lsp",
  "rust_analyzer",
  "terraformls",
  "yamlls",
}
local null_lss = {
  "prettierd",
  "stylua",
  "actionlint",
  "hadolint",
  "shellcheck",
  "shfmt",
  "gomodifytags",
  "gofumpt",
  "iferr",
  "impl",
  "goimports",
  "black",
  "isort",
  "tflint",
  "tfsec",
}
local daps = {
  "codelldb",
  "python",
  "coreclr",
  "bash",
  "dart",
  "delve",
}

-- customize mason plugins
return {
  vim.api.nvim_create_user_command(
    "MasonInstallAll",
    function()
      vim.cmd("LspInstall " .. table.concat(lspconfigs, " "))
      vim.cmd("NullLsInstall " .. table.concat(null_lss, " "))
      vim.cmd("DapInstall " .. table.concat(daps, " "))
    end,
    {}
  ),
  -- use mason-lspconfig to configure LSP installations
  {
    "williamboman/mason-lspconfig.nvim",
    -- overrides `require("mason-lspconfig").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astronvim.utils").list_insert_unique(opts.ensure_installed, lspconfigs)
    end,
  },
  -- use mason-null-ls to configure Formatters/Linter installation for null-ls sources
  {
    "jay-babu/mason-null-ls.nvim",
    -- overrides `require("mason-null-ls").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astronvim.utils").list_insert_unique(opts.ensure_installed, null_lss)
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    -- overrides `require("mason-nvim-dap").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astronvim.utils").list_insert_unique(opts.ensure_installed, daps)
    end,
  },
}
