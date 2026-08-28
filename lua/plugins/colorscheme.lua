return {
  {
    "ribru17/bamboo.nvim",
    lazy = true,
    priority = 1000,
    config = function()
      require("bamboo").setup()
      require("bamboo").load()
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    priority = 1000,
    config = function()
      require("kanagawa").setup {
        commentStyle = { italic = true },
        keywordStyle = { italic = true },
        statementStyle = { bold = true },
      }
    end,
  },
  {
    "taiwbi/bearded-theme.nvim",
    lazy = true,
    config = function() vim.g.bearded_variant = "monokai_stone" end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup {
        color_overrides = {
          mocha = {
            base = "#212121",
            mantle = "#212121",
            crust = "#212121",
          },
          macchiato = {
            base = "#212121",
            mantle = "#212121",
            crust = "#212121",
          },
          frappe = {
            base = "#212121",
            mantle = "#212121",
            crust = "#212121",
          },
          latte = {
            base = "#f2f4f8",
            mantle = "#e6e9ef",
            crust = "#dce0e8",
          },
        },
      }
    end,
  },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  {
    "scottmckendry/cyberdream.nvim",
    lazy = true,
    priority = 1000,
    opts = {
      options = {
        theme = "auto",
        italic_comments = true,
      },
    },
  },
  { "dgox16/oldworld.nvim", lazy = true, priority = 1000 },
  {
    "aktersnurra/no-clown-fiesta.nvim",
    lazy = true,
    priority = 1000,
    opts = {
      theme = "dark",
      styles = {
        type = { bold = true },
        lsp = { underline = false },
        match_paren = { underline = true },
      },
    },
  },
  { "shaunsingh/nord.nvim", lazy = true },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    priority = 1000,
    opts = {},
  },
  {
    "AlexvZyl/nordic.nvim",
    lazy = true,
    priority = 1000,
    config = function() require("nordic").load() end,
  },
  {
    "zenbones-theme/zenbones.nvim",
    lazy = true,
    dependencies = "rktjmp/lush.nvim",
    priority = 1000,
  },
  { "datsfilipe/min-theme.nvim", lazy = true },
  {
    "art220/dancheong.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "navarasu/onedark.nvim",
    priority = 1000,
    lazy = true,
  },
  {
    "nyoom-engineering/oxocarbon.nvim",
    lazy = true,
    build = false,
  },
  {
    "vague-theme/vague.nvim",
    lazy = true,
  },
}
