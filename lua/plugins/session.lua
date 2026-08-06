return {
  "stevearc/resession.nvim",
  lazy = true,
  opts = {
    options = {
      "binary",
      "bufhidden",
      "buflisted",
      "diff",
      "filetype",
      "modifiable",
      "previewwindow",
      "readonly",
      "scrollbind",
      "winfixheight",
      "winfixwidth",
    },
    buf_filter = function(bufnr) return require("util.buffer").is_valid(bufnr) end,
    tab_buf_filter = function(tabpage, bufnr) return vim.tbl_contains(vim.t[tabpage].bufs or {}, bufnr) end,
  },
  config = function(_, opts)
    local resession = require "resession"
    resession.setup(opts)

    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = vim.api.nvim_create_augroup("user_resession_autosave", { clear = true }),
      callback = function()
        local has_real = false
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if require("util.buffer").is_valid(b) and vim.api.nvim_buf_get_name(b) ~= "" then
            has_real = true
            break
          end
        end
        if has_real then resession.save("Last Session", { notify = false }) end
        resession.save(vim.fn.getcwd(), { dir = "dirsession", notify = false })
      end,
    })
  end,
}
