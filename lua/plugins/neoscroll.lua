return {
  "karb94/neoscroll.nvim",
  event = "VeryLazy",
  config = function()
    local neoscroll = require "neoscroll"

    neoscroll.setup {
      duration_multiplier = 0.5,
    }

    for key, lines in pairs {
      ["<ScrollWheelUp>"] = -3,
      ["<ScrollWheelDown>"] = 3,
    } do
      vim.keymap.set({ "n", "i", "v" }, key, function()
        neoscroll.scroll(lines, { move_cursor = false, duration = 60 })
      end, { silent = true })
    end
  end,
}
