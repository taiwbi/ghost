return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    main = "nvim-treesitter.configs",
    event = "VeryLazy",
    lazy = vim.fn.argc(-1) == 0,
    cmd = {
      "TSBufDisable", "TSBufEnable", "TSBufToggle",
      "TSDisable", "TSEnable", "TSToggle",
      "TSInstall", "TSInstallInfo", "TSInstallSync",
      "TSModuleInfo", "TSUninstall", "TSUpdate", "TSUpdateSync",
    },
    build = ":TSUpdate",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", lazy = true },
      { "JoosepAlviste/nvim-ts-context-commentstring", lazy = true, opts = { enable_autocmd = false } },
    },
    init = function(plugin)
      require("lazy.core.loader").add_to_rtp(plugin)
      pcall(require, "nvim-treesitter.query_predicates")
    end,
    opts = {
      auto_install = vim.fn.executable "tree-sitter" == 1,
      highlight = { enable = true },
      incremental_selection = { enable = true },
      indent = { enable = true },
      ensure_installed = {
        "bash", "c", "lua", "markdown", "markdown_inline", "python", "query", "vim", "vimdoc",
        "sql", "html", "css", "javascript", "php", "blade", "php_only",
        "scss", "rust", "hyprlang", "diff", "xml",
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["ak"] = { query = "@block.outer", desc = "around block" },
            ["ik"] = { query = "@block.inner", desc = "inside block" },
            ["ac"] = { query = "@class.outer", desc = "around class" },
            ["ic"] = { query = "@class.inner", desc = "inside class" },
            ["a?"] = { query = "@conditional.outer", desc = "around conditional" },
            ["i?"] = { query = "@conditional.inner", desc = "inside conditional" },
            ["af"] = { query = "@function.outer", desc = "around function" },
            ["if"] = { query = "@function.inner", desc = "inside function" },
            ["ao"] = { query = "@loop.outer", desc = "around loop" },
            ["io"] = { query = "@loop.inner", desc = "inside loop" },
            ["aa"] = { query = "@parameter.outer", desc = "around argument" },
            ["ia"] = { query = "@parameter.inner", desc = "inside argument" },
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]k"] = { query = "@block.outer", desc = "Next block start" },
            ["]f"] = { query = "@function.outer", desc = "Next function start" },
            ["]a"] = { query = "@parameter.inner", desc = "Next argument start" },
          },
          goto_next_end = {
            ["]K"] = { query = "@block.outer", desc = "Next block end" },
            ["]F"] = { query = "@function.outer", desc = "Next function end" },
            ["]A"] = { query = "@parameter.inner", desc = "Next argument end" },
          },
          goto_previous_start = {
            ["[k"] = { query = "@block.outer", desc = "Previous block start" },
            ["[f"] = { query = "@function.outer", desc = "Previous function start" },
            ["[a"] = { query = "@parameter.inner", desc = "Previous argument start" },
          },
          goto_previous_end = {
            ["[K"] = { query = "@block.outer", desc = "Previous block end" },
            ["[F"] = { query = "@function.outer", desc = "Previous function end" },
            ["[A"] = { query = "@parameter.inner", desc = "Previous argument end" },
          },
        },
        swap = {
          enable = true,
          swap_next = {
            [">K"] = { query = "@block.outer", desc = "Swap next block" },
            [">F"] = { query = "@function.outer", desc = "Swap next function" },
            [">A"] = { query = "@parameter.inner", desc = "Swap next argument" },
          },
          swap_previous = {
            ["<K"] = { query = "@block.outer", desc = "Swap previous block" },
            ["<F"] = { query = "@function.outer", desc = "Swap previous function" },
            ["<A"] = { query = "@parameter.inner", desc = "Swap previous argument" },
          },
        },
      },
    },
  },
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = {},
  },
}
