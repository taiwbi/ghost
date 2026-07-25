return {
  "supermaven-inc/supermaven-nvim",
  event = "InsertEnter",
  opts = {
    keymaps = {
      accept_suggestion = "<A-l>",
      clear_suggestion = "<C-]>",
      accept_word = "<C-j>",
    },
  },
}
