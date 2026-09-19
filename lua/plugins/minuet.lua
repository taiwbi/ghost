local code_filetypes = {
  "bash",
  "c",
  "cpp",
  "css",
  "go",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "lua",
  "php",
  "python",
  "rust",
  "scss",
  "sh",
  "sql",
  "svelte",
  "typescript",
  "typescriptreact",
  "vue",
  "blade",
}

return {
  {
    "milanglacier/minuet-ai.nvim",
    -- Setup must run before FileType so virtual text is enabled in the first
    -- file opened by Neovim. No network request is made until a suggestion is
    -- actually requested.
    lazy = false,
    keys = {
      {
        "<A-l>",
        function() require("minuet.virtualtext").action.accept() end,
        mode = "i",
        desc = "Accept AI completion",
      },
      {
        "<A-k>",
        function() require("minuet.virtualtext").action.accept_line() end,
        mode = "i",
        desc = "Accept AI completion line",
      },
      {
        "<M-n>",
        function() require("minuet.virtualtext").action.next() end,
        mode = "i",
        desc = "Next AI completion",
      },
      {
        "<M-p>",
        function() require("minuet.virtualtext").action.prev() end,
        mode = "i",
        desc = "Previous AI completion",
      },
      {
        "<A-x>",
        function()
          require("minuet.virtualtext").action.dismiss()
          return "<Ignore>"
        end,
        mode = "i",
        desc = "Dismiss AI completion",
        expr = true,
        nowait = true,
      },
      {
        "<Leader>mp",
        function() require("minuet.duet").action.predict() end,
        desc = "AI predict next edit",
      },
      {
        "<Leader>ma",
        function() require("minuet.duet").action.apply() end,
        desc = "Apply AI next edit",
      },
      {
        "<Leader>md",
        function() require("minuet.duet").action.dismiss() end,
        desc = "Dismiss AI next edit",
      },
      {
        "<Leader>mt",
        function() require("minuet.duet").action.toggle_auto_trigger() end,
        desc = "Toggle AI next-edit prediction",
      },
    },
    opts = {
      provider = "openai_compatible",
      request_timeout = 3,
      -- Delay requests enough to avoid one request per keystroke, while keeping
      -- the ghost text responsive when you pause naturally.
      throttle = 1800,
      debounce = 700,
      -- 8,000 characters is roughly 2,000 tokens: enough local context for
      -- useful completions without sending a large slice of every buffer.
      context_window = 8000,
      enable_predicates = {
        function() return vim.bo.buftype == "" and vim.bo.modifiable end,
      },
      provider_options = {
        openai_compatible = {
          api_key = "OPENROUTER_API_KEY",
          end_point = "https://openrouter.ai/api/v1/chat/completions",
          model = "deepseek/deepseek-v4-flash-0731",
          name = "OpenRouter",
          optional = {
            max_tokens = 56,
            top_p = 0.9,
            provider = { sort = "throughput" },
            reasoning_effort = "none",
          },
        },
      },
      virtualtext = {
        auto_trigger_ft = code_filetypes,
      },
      -- Duet is intentionally limited to code buffers and normal mode. This
      -- keeps edit predictions from competing with insert-mode ghost text or
      -- sending requests while navigating a buffer.
      duet = {
        provider = "openai_compatible",
        request_timeout = 12,
        provider_options = {
          openai_compatible = {
            api_key = "OPENROUTER_API_KEY",
            end_point = "https://openrouter.ai/api/v1/chat/completions",
            model = "deepseek/deepseek-v4-flash-0731",
            name = "OpenRouter",
            optional = {
              reasoning_effort = "none",
              provider = { sort = "throughput" },
            },
          },
        },
        auto_trigger = {
          debounce = 1000,
          -- Duet requests carry substantially more context than completion,
          -- so keep them on-demand through <Leader>mp by default.
          auto_trigger_ft = {},
          enable_predicates = {
            function()
              if vim.bo.buftype ~= "" or not vim.bo.modifiable or vim.fn.mode() ~= "n" then return false end

              local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
              return name ~= ".env" and not name:match "^%.env%."
            end,
          },
        },
      },
    },
  },
}
