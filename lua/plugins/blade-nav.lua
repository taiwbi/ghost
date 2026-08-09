return {
  "ricardoramirezr/blade-nav.nvim",
  ft = { "blade", "php" },
  opts = {
    integrations = {
      -- Completion is provided by blink.cmp through blink.compat below.
      -- Avoid BladeNav's deprecated nvim-cmp integration and its startup warning.
      cmp = false,
    },
    annotations = {
      -- Keep `K` for LSP hover. BladeNav's value lookup remains available
      -- through its commands and inline annotations.
      create_keymaps = false,
    },
  },
  dependencies = { "saghen/blink.compat" },
  specs = {
    {
      "saghen/blink.cmp",
      optional = true,
      opts = {
        sources = {
          default = { "blade_nav" },
          providers = {
            blade_nav = {
              name = "blade-nav",
              module = "blink.compat.source",
              min_keyword_length = 1,
              score_offset = -1,
            },
          },
        },
      },
    },
  },
}
