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
}
