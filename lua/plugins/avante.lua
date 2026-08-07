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
    { "<leader>al", function() require("avante.api").ask() end, desc = "AI Ask", mode = { "n", "v" } }
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
  opts = {
    provider = "openrouter",
    auto_suggestions_provider = "openrouter",
    providers = {
      openrouter = {
        __inherited_from = "openai",
        endpoint = "https://openrouter.ai/api/v1",
        api_key_name = "OPENROUTER_API_KEY",
        model = "openai/gpt-5.6-luna",
        extra_request_body = {
          provider = {
            sort = "price",
          },
        },
      },
    },
    behaviour = {
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
