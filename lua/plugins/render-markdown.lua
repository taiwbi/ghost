return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown", "Avante" },
  opts = {
    file_types = { "markdown", "Avante" },
    overrides = {
      buftype = {
        nofile = { enabled = false },
      },
      filetype = {
        Avante = { enabled = true },
      },
    },
  },
}
