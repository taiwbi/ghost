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
      -- Give local inference time to return, while triggering after a short
      -- pause in typing. Keep the context modest for this small model.
      request_timeout = 15,
      throttle = 800,
      debounce = 180,
      context_window = 4000,
      n_completions = 1,
      enable_predicates = {
        function() return vim.bo.buftype == "" and vim.bo.modifiable end,
      },
      provider_options = {
        openai_compatible = {
          -- Ollama's OpenAI-compatible endpoint accepts any non-empty key.
          api_key = function() return "ollama" end,
          end_point = "http://localhost:11434/v1/chat/completions",
          model = "deepseek-coder:1.3b",
          name = "Ollama",
          system = {
            template = "{{{prompt}}}\n{{{guidelines}}}\n{{{n_completion_template}}}",
            prompt = [[
You are an inline code completion engine. The input contains the text before and after the cursor, plus the file language.
Return only the exact text to insert at <cursorPosition>, continuing the existing code in that language.
]],
            guidelines = [[
Rules:
1. Output only the code or text to insert. Do not explain your answer.
2. Never output Markdown, triple backticks, a language label, or a code fence.
3. Do not repeat text already present before or after the cursor.
4. Preserve the existing indentation and style. Keep the completion short and useful.
]],
            n_completion_template = "Return at most %d completion.",
          },
          optional = {
            max_tokens = 56,
            top_p = 0.9,
            temperature = 0.1,
            provider = { sort = "throughput" },
            reasoning_effort = "none",
          },
        },
      },
      virtualtext = {
        auto_trigger_ft = code_filetypes,
        -- Blink often has its completion menu open while typing; keep Minuet's
        -- ghost text visible alongside it instead of silently suppressing it.
        show_on_completion_menu = true,
      },
      -- Duet is intentionally limited to code buffers and normal mode. This
      -- keeps edit predictions from competing with insert-mode ghost text or
      -- sending requests while navigating a buffer.
      duet = {
        provider = "openai_compatible",
        request_timeout = 12,
        provider_options = {
          openai_compatible = {
            api_key = function() return "ollama" end,
            end_point = "http://localhost:11434/v1/chat/completions",
            model = "deepseek-coder:1.3b",
            name = "Ollama",
            optional = {
              temperature = 0.1,
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
