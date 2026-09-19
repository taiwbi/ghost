return {
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    config = function()
      local dap, sign = require "dap", vim.fn.sign_define
      sign("DapBreakpoint", { text = "●", texthl = "DiagnosticError", numhl = "DiagnosticError" })
      sign("DapBreakpointCondition", { text = "◐", texthl = "DiagnosticWarn", numhl = "DiagnosticWarn" })
      sign("DapBreakpointRejected", { text = "●", texthl = "Comment", numhl = "" })
      sign("DapLogPoint", { text = "◆", texthl = "DiagnosticInfo", numhl = "" })
      sign("DapStopped", { text = "▶", texthl = "DiagnosticWarn", numhl = "DiagnosticWarn" })

      dap.adapters.php = {
        type = "executable",
        command = "node",
        args = { os.getenv "HOME" .. "/.local/share/nvim/mason/packages/php-debug-adapter/extension/out/phpDebug.js" },
      }

      local listen_for_xdebug = setmetatable({
        type = "php",
        request = "launch",
        name = "Listen for Xdebug",
        port = 9003,
      }, {
        __call = function(config)
          local project_root = vim.fs.root(0, { "composer.json", ".git" }) or vim.fn.getcwd()

          if vim.fn.filereadable(project_root .. "/vendor/bin/sail") == 1 then
            return vim.tbl_extend("force", config, {
              pathMappings = {
                ["/var/www/html"] = project_root,
              },
            })
          end

          return config
        end,
      })

      dap.configurations.php = {
        listen_for_xdebug,
        {
          name = "Launch currently open script",
          type = "php",
          request = "launch",
          program = "${file}",
          cwd = "${fileDirname}",
          port = 0,
          runtimeArgs = { "-dxdebug.start_with_request=yes" },
          env = {
            XDEBUG_MODE = "debug,develop",
            XDEBUG_CONFIG = "client_port=${port}",
          },
        },
      }
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "mfussenegger/nvim-dap", "williamboman/mason.nvim" },
    cmd = { "DapInstall", "DapUninstall" },
    opts = {
      ensure_installed = {},
      handlers = {},
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    lazy = true,
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    opts = { floating = { border = "rounded" } },
    config = function(_, opts)
      local dap, dapui = require "dap", require "dapui"
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },
}
