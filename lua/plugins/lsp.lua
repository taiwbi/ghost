local server_settings = {
  basedpyright = {
    settings = {
      basedpyright = {
        analysis = {
          typeCheckingMode = "basic",
          autoImportCompletions = true,
          diagnosticSeverityOverrides = {
            reportUnusedImport = "information",
            reportUnusedFunction = "information",
            reportUnusedVariable = "information",
            reportGeneralTypeIssues = "none",
            reportOptionalMemberAccess = "none",
            reportOptionalSubscript = "none",
            reportPrivateImportUsage = "none",
            reportUnknownParameterType = "none",
            reportMissingParameterType = "none",
          },
        },
      },
    },
  },
  lua_ls = {
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        completion = { callSnippet = "Replace" },
        format = { enable = false },
      },
    },
  },
  phptools = {
    cmd = { "devsense-php-ls", "--stdio" },
    filetypes = { "php", "blade" },
    root_markers = { "composer.json", ".git" },
    -- Neovim disables dynamic file watching on Linux by default. PHP Tools
    -- relies on it to notice generated helpers and other out-of-editor edits.
    capabilities = {
      workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true,
        },
      },
    },
    init_options = {
      ["0"] = vim.fn.readfile(vim.fn.expand("~/.keys/DEVSENSE"))[1] or "",
    },
  },
  jsonls = {
    handlers = {
      ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
        if result and result.diagnostics then
          result.diagnostics = vim.tbl_filter(function(diag)
            return diag.code ~= 519
          end, result.diagnostics)
        end
        vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
      end,
      ["textDocument/diagnostic"] = function(err, result, ctx, config)
        if result and result.items then
          result.items = vim.tbl_filter(function(diag)
            return diag.code ~= 519
          end, result.items)
        end
        vim.lsp.handlers["textDocument/diagnostic"](err, result, ctx, config)
      end,
    },
  },
}

local default_servers = {
  "lua_ls",
  "html",
  "cssls",
  "tailwindcss",
  "ts_ls",
  "jsonls",
  "basedpyright",
  "rust_analyzer",
  "phptools",
}

local function setup_diagnostics()
  vim.diagnostic.config {
    virtual_text = true,
    virtual_lines = false,
    underline = true,
    severity_sort = true,
    float = { border = "rounded", source = true },
    signs = false,
  }
end

local function on_attach(client, bufnr)
  if client.server_capabilities.documentHighlightProvider then
    local group = vim.api.nvim_create_augroup("lsp_document_highlight_" .. bufnr, { clear = true })
    vim.api.nvim_create_autocmd("CursorHold", {
      group = group,
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = group,
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
    })
  end

  if client.server_capabilities.codeLensProvider and vim.g.codelens_enabled ~= false then
    vim.g.codelens_enabled = true
    vim.api.nvim_create_autocmd({ "InsertLeave", "BufEnter" }, {
      group = vim.api.nvim_create_augroup("lsp_codelens_" .. bufnr, { clear = true }),
      buffer = bufnr,
      callback = function()
        if vim.g.codelens_enabled then vim.lsp.codelens.refresh { bufnr = bufnr } end
      end,
    })
  end
end

return {
  { "folke/neoconf.nvim", lazy = true, opts = {} },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "folke/neoconf.nvim",
      {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        cmd = { "LspInstall", "LspUninstall" },
        opts = {
          ensure_installed = {},
          automatic_installation = false,
        },
      },
    },
    cmd = { "LspLog" },
    config = function()
      setup_diagnostics()

      for name, cfg in pairs(server_settings) do
        vim.lsp.config(name, cfg)
      end

      for _, name in ipairs(default_servers) do
        vim.lsp.enable(name)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client then on_attach(client, args.buf) end
        end,
      })

      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup("user_lsp_detach", { clear = true }),
        callback = function(args)
          pcall(vim.api.nvim_del_augroup_by_name, "lsp_document_highlight_" .. args.buf)
          pcall(vim.api.nvim_del_augroup_by_name, "lsp_codelens_" .. args.buf)
        end,
      })

      -- Neovim 0.11+ exposes :lsp natively; lspconfig no longer registers these.
      -- vim.api.nvim_create_user_command("lsp info", "checkhealth vim.lsp", { desc = "LSP info" })
    end,
  },
}
