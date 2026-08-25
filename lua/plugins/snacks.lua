local buffer = require "util.buffer"

return {
  "folke/snacks.nvim",
  url = "https://github.com/taiwbi/snacks.nvim.git",
  branch = "ghostty-fix",
  lazy = false,
  priority = 1000,
  opts = {
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true },
    image = { doc = { enabled = true } },
    picker = { ui_select = true },
    explorer = { enabled = true },
    indent = {
      indent = { char = "▏" },
      scope = { char = "▏" },
      filter = function(bufnr)
        return buffer.is_valid(bufnr) and vim.g.snacks_indent ~= false and vim.b[bufnr].snacks_indent ~= false
      end,
      animate = { enabled = false },
    },
    scope = { filter = function(bufnr) return buffer.is_valid(bufnr) end },
    zen = {
      toggles = { dim = false, diagnostics = false, inlay_hints = false },
      win = {
        width = function() return math.min(120, math.floor(vim.o.columns * 0.75)) end,
        height = 0.9,
        backdrop = { transparent = false, win = { wo = { winhighlight = "Normal:Normal" } } },
        wo = {
          number = false,
          relativenumber = false,
          signcolumn = "no",
          foldcolumn = "0",
          winbar = "",
          list = false,
          showbreak = "NONE",
        },
      },
    },
    dashboard = {
      preset = {
        header = {
          { "██╗              ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗\n", hl = "DiagnosticInfo" },
          { "╚██╗            ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝\n", hl = "DiagnosticInfo" },
          { " ╚██╗           ██║  ███╗███████║██║   ██║███████╗   ██║   \n", hl = "DiagnosticWarn" },
          { " ██╔╝           ██║   ██║██╔══██║██║   ██║╚════██║   ██║   \n", hl = "DiagnosticWarn" },
          { "██╔╝███████╗    ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║   \n", hl = "DiagnosticError" },
          { "╚═╝ ╚══════╝     ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   \n\n", hl = "DiagnosticError" },
          { "Computers were a mistake. Anyway—", hl = "Comment" },
        },
      },
      sections = {
        { pane = 1, section = "header", padding = 2 },
        { pane = 1, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
        { pane = 1, section = "startup" },
      },
    },
  },
}
