local fn = require "user.util.fn"
local telescope = require "user.util.telescope"

return {
  "mfussenegger/nvim-dap",
  enabled = true,
  dependencies = {
    "linux-cultist/venv-selector.nvim",
    -- { "theHamsta/nvim-dap-virtual-text", config = true },
  },
  config = function()
    local dap = require "dap"
    local CODELLDB_DIR = require("mason-registry").get_package("codelldb"):get_install_path()
      .. "/extension/adapter/codelldb"
    local NODE_DIR = require("mason-registry").get_package("node-debug2-adapter"):get_install_path()
      .. "/out/src/nodeDebug.js"

    dap.adapters.codelldb = {
      name = "codelldb",
      type = "server",
      host = "127.0.0.1",
      port = "${port}",
      executable = {
        command = CODELLDB_DIR,
        args = { "--port", "${port}" },
      },
      detatched = false,
    }
    dap.adapters.node = {
      type = "executable",
      command = "node",
      args = { NODE_DIR },
    }
    dap.adapters.coreclr = {
      type = "executable",
      command = "/usr/local/netcoredbg",
      args = { "--interpreter=vscode" },
    }

    -- configurations --

    local lldb = {
      name = "Launch",
      type = "codelldb",
      request = "launch",
      program = function()
        if not vim.g.dap_program or #vim.g.dap_program == 0 then
          vim.g.dap_program = vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end
        return vim.g.dap_program
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      args = {},
    }

    dap.configurations.c = {
      lldb,
    }
    dap.configurations.cpp = {
      lldb,
    }
    dap.configurations.rust = {
      lldb,
    }
    dap.configurations.javascript = {
      {
        name = "Launch",
        type = "node",
        request = "launch",
        program = "${file}",
        cwd = vim.fn.getcwd(),
        sourceMaps = true,
        protocol = "inspector",
        console = "integratedTerminal",
      },
      {
        -- For this to work you need to make sure the node process is started with the `--inspect` flag.
        name = "Attach to process - test",
        type = "node",
        request = "attach",
        processId = require("dap.utils").pick_process,
      },
    }
    dap.configurations.cs = {
      {
        type = "coreclr",
        name = "launch - netcoredbg",
        request = "launch",
        -- TODO: Add a functionality to pick the project to debug
        program = "${workspaceFolder}/bin/Debug/net7.0/${workspaceFolderBasename}.dll",
      },
    }
  end,
}
