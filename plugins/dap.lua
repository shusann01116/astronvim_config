local fn = require "user.util.fn"
local telescope = require "user.util.telescope"

return {
  "mfussenegger/nvim-dap",
  enabled = true,
  dependencies = {
    "catppuccin/nvim",
    "linux-cultist/venv-selector.nvim",
  },
  config = function()
    local dap = require "dap"

    -- cattpuccin integration
    local sign = vim.fn.sign_define
    sign("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
    sign("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
    sign("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" })

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
  end,
}
