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

local function accept_and_continue(n_lines)
  local action = require("minuet.virtualtext").action
  if not action.is_visible() then return end

  local bufnr = vim.api.nvim_get_current_buf()
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
  action.accept(n_lines)

  -- Let Minuet's scheduled insertion and cursor events finish first.
  vim.defer_fn(function()
    if vim.api.nvim_get_current_buf() ~= bufnr or vim.fn.mode() ~= "i" then return end
    if vim.api.nvim_buf_get_changedtick(bufnr) == changedtick then return end
    -- Line acceptance keeps the rest of a multi-line suggestion available.
    if n_lines and action.is_visible() then return end
    action.dismiss() -- Cancel any pending automatic request before continuing.
    action.next()
  end, 10)
end

return {
  {
    "milanglacier/minuet-ai.nvim",
    -- Setup must run before FileType so virtual text is enabled in the first
    -- file opened by Neovim. No network request is made until a suggestion is
    -- actually requested.
    lazy = false,
    config = function(_, opts)
      require("minuet").setup(opts)
      require("util.minuet_completion").install()
    end,
    keys = {
      {
        "<A-l>",
        function() accept_and_continue() end,
        mode = "i",
        desc = "Accept AI completion",
      },
      {
        "<A-k>",
        function() accept_and_continue(1) end,
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
      provider = "openai_fim_compatible",
      -- Keep surrounding code visible to FIM, especially the existing suffix.
      -- context_window is characters, not tokens.
      -- Streaming lets Minuet salvage partial output if inference hits the timeout.
      request_timeout = 60,
      throttle = 150,
      debounce = 75,
      context_window = 1024,
      context_ratio = 0.65,
      -- The local guard removes duplicates without trimming FIM whitespace.
      before_cursor_filter_length = 0,
      after_cursor_filter_length = 0,
      n_completions = 1,
      enable_predicates = {
        function() return vim.bo.buftype == "" and vim.bo.modifiable end,
      },
      provider_options = {
        openai_fim_compatible = {
          api_key = function()
            local file = io.open(vim.fn.expand("~/.keys/DEEPINFRA"), "r")
            if not file then return nil end
            local key = file:read("*all"):gsub("%s+", "")
            file:close()
            return key ~= "" and key or nil
          end,
          end_point = "https://api.deepinfra.com/v1/inference/",
          model = "Qwen/Qwen3-Coder-480B-A35B-Instruct-Turbo",
          name = "DeepInfra",
          stream = true,
          template = {
            prompt = function(before, after)
              local utils = require("minuet.utils")
              return "<|fim_prefix|>"
                .. utils.add_language_comment()
                .. "\n"
                .. utils.add_tab_comment()
                .. "\n"
                .. before
                .. "<|fim_suffix|>"
                .. after
                .. "<|fim_middle|>"
            end,
            -- DeepInfra's inference endpoint expects Qwen's FIM markers in input.
            suffix = false,
          },
          transform = {
            function(args)
              args.end_point = args.end_point .. args.body.model
              args.body.input = args.body.prompt
              args.body.model = nil
              args.body.prompt = nil
              return args
            end,
          },
          get_text_fn = {
            no_stream = function(json) return json.results[1].generated_text end,
            stream = function(json) return json.token.text end,
          },
          optional = {
            max_tokens = 32,
            temperature = 0,
            stop = { "<|endoftext|>" },
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
