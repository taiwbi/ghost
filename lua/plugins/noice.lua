return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    notify = {
      enabled = true,
      view = "mini",
    },
    messages = {
      view = "mini",
      view_error = "mini",
      view_warn = "mini",
    },
    lsp = {
      hover = {
        -- Multiple attached clients may legitimately have no hover result.
        -- Keep the useful response without showing one notification per client.
        silent = true,
      },
      message = {
        enabled = true,
        view = "mini",
      },
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = false,
      },
    },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
}
