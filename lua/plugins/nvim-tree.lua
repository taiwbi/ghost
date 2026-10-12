return {
  "nvim-tree/nvim-tree.lua",
  cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFindFile" },
  dependencies = { "echasnovski/mini.icons" },
  opts = {
    hijack_netrw = true,
    update_focused_file = { enable = true },
    view = {
      width = 32,
      side = "left",
    },
    renderer = {
      root_folder_label = false,
      indent_markers = { enable = true },
    },
    filters = {
      dotfiles = false,
    },
    git = {
      enable = false,
    },
  },
}
