local format_on_save = function(bufnr)
  if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then return end
  vim.lsp.buf.format {
    bufnr = bufnr,
    timeout_ms = 5000,
    filter = function(client) return client.name ~= "phptools" end,
  }
end

return {
  "nvimtools/none-ls.nvim",
  main = "null-ls",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "jay-babu/mason-null-ls.nvim",
      dependencies = { "williamboman/mason.nvim" },
      cmd = { "NullLsInstall", "NullLsUninstall" },
      opts = { ensure_installed = {}, handlers = {} },
    },
  },
  config = function()
    local null_ls = require "null-ls"
    null_ls.setup {
      sources = {
        null_ls.builtins.formatting.blade_formatter.with {
          command = "blade-formatter",
          args = {
            "-i",
            vim.opt.tabstop:get(),
            "--sort-tailwindcss-classes",
            "--indent-inner-html",
            "--write",
            "$FILENAME",
          },
        },
      },
      on_attach = function(client, bufnr)
        if client:supports_method("textDocument/formatting", bufnr) then
          local group = vim.api.nvim_create_augroup("null_ls_format_" .. bufnr, { clear = true })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = group,
            buffer = bufnr,
            callback = function() format_on_save(bufnr) end,
          })
        end
      end,
    }
  end,
}
