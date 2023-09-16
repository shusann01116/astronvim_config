local os, arch = require("user.util.get_os_name").get_os_name()

local lspconfigs = {
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
  "terraformls",
  "yamlls",
}
local null_lss = {
  "prettierd",
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
  "python",
  "bash",
  "dart",
  "delve",
}

if arch == "x86_64" or arch == "x86" then
  table.insert(lspconfigs, "lua_ls")
  table.insert(lspconfigs, "rust_analyzer")
  table.insert(null_lss, "stylua")
  table.insert(daps, "codelldb")
  table.insert(daps, "coreclr")
end

-- customize mason plugins
return {
  vim.api.nvim_create_user_command("MasonInstallAll", function()
    vim.cmd("LspInstall " .. table.concat(lspconfigs, " "))
    vim.cmd("NullLsInstall " .. table.concat(null_lss, " "))
    vim.cmd("DapInstall " .. table.concat(daps, " "))
  end, {}), -- use mason-lspconfig to configure LSP installations
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
