-- Removed themes (tried and didn't like):
-- bamboo.nvim, kanagawa.nvim, bearded-theme.nvim, catppuccin, rose-pine,
-- nord.nvim, nordic.nvim, min-theme.nvim, dancheong.nvim, onedark.nvim,
-- oxocarbon.nvim, vesper.nvim
return {
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
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    priority = 1000,
    opts = { contrast = vim.o.background == "dark" and "hard" or "soft" },
  },
  {
    "zenbones-theme/zenbones.nvim",
    lazy = true,
    dependencies = "rktjmp/lush.nvim",
    priority = 1000,
  },
  {
    "vague-theme/vague.nvim",
    lazy = true,
  },
  {
    "wtfox/jellybeans.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
}
