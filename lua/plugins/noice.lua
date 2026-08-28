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
        opts = {
          size = {
            max_width = 80,
            max_height = 9,
          },
        },
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
  config = function(_, opts)
    require("noice").setup(opts)

    -- Noice separates fenced code blocks from surrounding Markdown.
    -- Disable that.
    local markdown = require "noice.text.markdown"
    local markdown_format = markdown.format
    markdown.format = function(message, ...)
      local result = markdown_format(message, ...)
      if message.event == "lsp" and message.kind == "hover" then message:trim_empty_lines() end
      return result
    end

    -- WORKAROUND: Neovim 0.11+ emits confirmations as separate message and
    -- cmdline events. Noice can incorrectly deduplicate a repeated confirmation
    -- after choosing "No", or treat a re-sent choice prompt after an invalid
    -- key as a normal cmdline popup. Remove this once Noice fixes the upstream
    -- confirmation-event handling.
    local state = require "noice.ui.state"
    local msg = require "noice.ui.msg"
    local cmdline = require "noice.ui.cmdline"
    local on_confirm = msg.on_confirm
    local on_show = cmdline.on_show
    local on_hide = cmdline.on_hide
    local confirmation_active = false
    local confirmation_hidden = false

    msg.on_confirm = function(event, kind, content)
      state.clear(event)
      return on_confirm(event, kind, content)
    end

    cmdline.on_show = function(...)
      local pending_confirmation = cmdline.confirm_message ~= nil
      if confirmation_active and not pending_confirmation then
        confirmation_hidden = false
        return
      end
      local result = on_show(...)
      confirmation_active = pending_confirmation or confirmation_active
      return result
    end

    cmdline.on_hide = function(event, level)
      if not confirmation_active then return on_hide(event, level) end

      -- An invalid answer briefly hides and immediately re-shows the cmdline.
      -- Delay cleanup so that re-show keeps using the active confirmation view.
      confirmation_hidden = true
      vim.defer_fn(function()
        if not confirmation_hidden then return end
        confirmation_hidden = false
        confirmation_active = false
        on_hide(event, level)
      end, 50)
    end
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
}
