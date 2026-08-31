return {
  "nvim-mini/mini.diff",
  version = "*",
  enabled = vim.fn.executable "git" == 1,
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    -- Keep Gitsigns as the visible gutter and Git-action provider. MiniDiff's
    -- lower-priority signs only maintain the state required for its overlay.
    view = {
      style = "sign",
      priority = 1,
      signs = {
        add = "▎",
        change = "▎",
        delete = "_",
      },
    },
    -- Match Neovim's best built-in diff strategy while allowing larger hunks
    options = {
      algorithm = "histogram",
      indent_heuristic = true,
      linematch = 200,
      wrap_goto = false,
    },
    mappings = {
      apply = "",
      reset = "",
      textobject = "",
      goto_first = "",
      goto_prev = "",
      goto_next = "",
      goto_last = "",
    },
  },
  config = function(_, opts)
    require("mini.diff").setup(opts)

    -- MiniDiff calls old lines in a replacement a "change" and colors them
    -- with DiffText by default. Treat every old virtual line as a deletion so
    -- it uses the theme's red deleted-line background instead.
    local function apply_overlay_highlights()
      for _, group in ipairs { "MiniDiffOverDelete", "MiniDiffOverChange", "MiniDiffOverContext" } do
        vim.api.nvim_set_hl(0, group, { link = "DiffDelete" })
      end
      vim.api.nvim_set_hl(0, "MiniDiffOverChangeBuf", { link = "DiffChange" })
    end

    apply_overlay_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("user_minidiff_highlights", { clear = true }),
      desc = "Keep MiniDiff old lines styled as deletions",
      callback = apply_overlay_highlights,
    })
  end,
}
