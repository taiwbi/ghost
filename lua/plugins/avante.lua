return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false, -- Never set this value to "*"!
  build = vim.fn.has("win32") ~= 0
      and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make",
  keys = {
    { "<leader>ae", function() require("avante.api").edit() end, desc = "AI Edit", mode = { "n", "v" } },
    { "<leader>al", function() require("avante.api").ask() end, desc = "AI Ask", mode = { "n", "v" } },
    {
      "<leader>ac",
      function()
        local api = require "avante.api"
        if require("avante.config").provider ~= "codex" then api.switch_provider "codex" end
        local avante = require "avante"
        if avante.is_sidebar_open() then avante.close_sidebar() end
        api.ask { new_chat = true }
      end,
      desc = "Codex Chat",
      mode = "n",
    },
    { "<leader>am", function() require("avante.api").select_acp_model() end, desc = "Codex Model" },
    {
      "<leader>ar",
      function() require("avante.acp_config_selector").open("thought_level", "Codex Reasoning Effort> ") end,
      desc = "Codex Reasoning Effort",
    },
    { "<leader>aM", function() require("avante.api").select_acp_mode() end, desc = "Codex Mode" },
    { "<leader>ah", function() require("avante.api").select_history() end, desc = "AI Chat History" },
    { "<leader>as", function() require("avante.api").stop() end, desc = "AI Stop" },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "saghen/blink.compat",
    "MeanderingProgrammer/render-markdown.nvim",
  },
  opts = {
    -- Codex runs through ACP, preserving its agentic tools and ChatGPT login.
    provider = "codex",
    auto_suggestions_provider = "openrouter",
    selector = {
      provider = "snacks",
    },
    acp_providers = {
      codex = {
        command = "codex-acp",
        env = {
          HOME = vim.env.HOME,
          PATH = vim.env.PATH,
          CODEX_PATH = vim.fn.exepath "codex",
          NODE_NO_WARNINGS = "1",
        },
      },
    },
    providers = {
      openrouter = {
        __inherited_from = "openai",
        endpoint = "https://openrouter.ai/api/v1",
        api_key_name = "OPENROUTER_API_KEY",
        model = "z-ai/glm-5.3",
        extra_request_body = {
          provider = {
            sort = "price",
          },
        },
      },
    },
    behaviour = {
      auto_add_current_file = false,
      auto_suggestions = false,
      auto_set_keymaps = false,
    },
    mappings = {
      diff = {
        ours = "co",
        theirs = "ct",
        all_theirs = "ca",
        both = "cb",
        cursor = "cc",
        next = "]x",
        prev = "[x",
      },
      suggestion = {
        accept = "<M-l>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
      jump = {
        next = "]]",
        prev = "[[",
      },
      submit = {
        normal = "<CR>",
        insert = "<C-s>",
      },
      cancel = {
        normal = { "<C-c>", "<Esc>", "q" },
        insert = { "<C-c>" },
      },
      sidebar = {
        apply_all = "A",
        apply_cursor = "a",
        retry_user_request = "r",
        edit_user_request = "e",
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
        remove_file = "d",
        add_file = "@",
        close = { "<Esc>", "q" },
      },
    },
  },
  config = function(_, opts)
    -- Read API key from ~/.keys/OPENROUTER
    local key_file = vim.fn.expand("~/.keys/OPENROUTER")
    local f = io.open(key_file, "r")
    if f then
      local key = f:read("*all"):gsub("%s+", "")
      f:close()
      vim.env.OPENROUTER_API_KEY = key
    end

    require("avante").setup(opts)
  end,
}
