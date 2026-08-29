return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    spec = {
      { "<Leader>a", group = "AI", mode = { "n", "v" } },
      { "<Leader>b", group = "Buffers" },
      { "<Leader>bs", group = "Sort buffers by..." },
      { "<Leader>d", group = "Debugger" },
      { "<Leader>D", group = "Database" },
      { "<Leader>f", group = "Find" },
      { "<Leader>g", group = "Git" },
      { "<Leader>l", group = "LSP" },
      { "<Leader>p", group = "Packages" },
      { "<Leader>r", group = "Helpers" },
      { "<Leader>S", group = "Session" },
      { "<Leader>t", group = "Terminal" },
      { "<Leader>u", group = "UI/UX" },
      { "<Leader>x", group = "Lists" },
    },
  },
  config = function(_, opts)
    require("which-key").setup(opts)

    local view = require "which-key.view"
    if not view._statusline_redraw then
      local update = view.update
      local hide = view.hide

      view.update = function(...)
        update(...)
        vim.cmd.redrawstatus()
      end
      view.hide = function(...)
        hide(...)
        vim.cmd.redrawstatus()
      end

      -- check_overlap pushes the window below the cursor when it would cover
      -- it, but the pushed-down geometry ignores the window border and the
      -- statusline row, so the popup ends up rendered on top of the statusline.
      view.check_overlap = function(wopts)
        local row, col = vim.fn.screenrow(), vim.fn.screencol()
        local overlaps = (row >= wopts.row and row <= wopts.row + wopts.height)
          and (col >= wopts.col and col <= wopts.col + wopts.width)
        if not overlaps then return end

        -- try to move below the cursor, clamped so the popup (including its
        -- border) never crosses the statusline row
        local new_row = row + 1
        local new_height = vim.o.lines - vim.o.cmdheight - 3 - new_row
        if new_height >= 4 then
          wopts.row = new_row
          wopts.height = math.min(wopts.height, new_height)
        end
        -- not enough room below: keep the default position above the statusline
      end

      view._statusline_redraw = true
    end
  end,
}
