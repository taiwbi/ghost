local parsers = {
  "bash", "c", "lua", "markdown", "markdown_inline", "python", "query", "vim", "vimdoc",
  "sql", "html", "css", "javascript", "php", "blade", "php_only",
  "scss", "rust", "hyprlang", "diff", "xml",
}

local textobjects = {
  select = {
    ["ak"] = "@block.outer",
    ["ik"] = "@block.inner",
    ["ac"] = "@class.outer",
    ["ic"] = "@class.inner",
    ["a?"] = "@conditional.outer",
    ["i?"] = "@conditional.inner",
    ["af"] = "@function.outer",
    ["if"] = "@function.inner",
    ["ao"] = "@loop.outer",
    ["io"] = "@loop.inner",
    ["aa"] = "@parameter.outer",
    ["ia"] = "@parameter.inner",
  },
  next_start = { ["]k"] = "@block.outer", ["]f"] = "@function.outer", ["]a"] = "@parameter.inner" },
  next_end = { ["]K"] = "@block.outer", ["]F"] = "@function.outer", ["]A"] = "@parameter.inner" },
  previous_start = { ["[k"] = "@block.outer", ["[f"] = "@function.outer", ["[a"] = "@parameter.inner" },
  previous_end = { ["[K"] = "@block.outer", ["[F"] = "@function.outer", ["[A"] = "@parameter.inner" },
  swap_next = { [">K"] = "@block.outer", [">F"] = "@function.outer", [">A"] = "@parameter.inner" },
  swap_previous = { ["<K"] = "@block.outer", ["<F"] = "@function.outer", ["<A"] = "@parameter.inner" },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    cmd = { "TSInstall", "TSInstallFromGrammar", "TSUninstall", "TSUpdate", "TSLog" },
    dependencies = {
      { "JoosepAlviste/nvim-ts-context-commentstring", lazy = true, opts = { enable_autocmd = false } },
    },
    config = function()
      local ts = require "nvim-treesitter"
      ts.setup()
      if vim.fn.executable "tree-sitter" == 1 then
        ts.install(parsers)
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = parsers,
        callback = function()
          if pcall(vim.treesitter.start) then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    lazy = false,
    config = function()
      require("nvim-treesitter-textobjects").setup {
        select = { lookahead = true },
        move = { set_jumps = true },
      }

      for lhs, query in pairs(textobjects.select) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
        end)
      end

      for kind, mappings in pairs {
        goto_next_start = textobjects.next_start,
        goto_next_end = textobjects.next_end,
        goto_previous_start = textobjects.previous_start,
        goto_previous_end = textobjects.previous_end,
      } do
        for lhs, query in pairs(mappings) do
          vim.keymap.set({ "n", "x", "o" }, lhs, function()
            require("nvim-treesitter-textobjects.move")[kind](query, "textobjects")
          end)
        end
      end

      for lhs, query in pairs(textobjects.swap_next) do
        vim.keymap.set("n", lhs, function()
          require("nvim-treesitter-textobjects.swap").swap_next(query, "textobjects")
        end)
      end
      for lhs, query in pairs(textobjects.swap_previous) do
        vim.keymap.set("n", lhs, function()
          require("nvim-treesitter-textobjects.swap").swap_previous(query, "textobjects")
        end)
      end
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = {},
  },
}
