local opt = vim.opt

opt.backspace:append "nostop"
opt.breakindent = true
opt.clipboard = "unnamedplus"

-- Prefer the active desktop's clipboard, including X11 sessions with stale Wayland variables.
if
  vim.env.XDG_SESSION_TYPE ~= "x11"
  and vim.env.WAYLAND_DISPLAY
  and vim.env.WAYLAND_DISPLAY ~= ""
  and vim.fn.executable "wl-copy" == 1
  and vim.fn.executable "wl-paste" == 1
then
  vim.g.clipboard = {
    name = "wl-copy",
    copy = {
      ["+"] = { "wl-copy", "--type", "text/plain" },
      ["*"] = { "wl-copy", "--primary", "--type", "text/plain" },
    },
    paste = {
      ["+"] = { "wl-paste", "--no-newline" },
      ["*"] = { "wl-paste", "--no-newline", "--primary" },
    },
    cache_enabled = 1,
  }
elseif vim.env.DISPLAY and vim.env.DISPLAY ~= "" and vim.fn.executable "xclip" == 1 then
  vim.g.clipboard = {
    name = "xclip",
    copy = {
      ["+"] = { "xclip", "-quiet", "-i", "-selection", "clipboard" },
      ["*"] = { "xclip", "-quiet", "-i", "-selection", "primary" },
    },
    paste = {
      ["+"] = { "xclip", "-o", "-selection", "clipboard" },
      ["*"] = { "xclip", "-o", "-selection", "primary" },
    },
    cache_enabled = 1,
  }
elseif vim.env.DISPLAY and vim.env.DISPLAY ~= "" and vim.fn.executable "xsel" == 1 then
  vim.g.clipboard = {
    name = "xsel",
    copy = {
      ["+"] = { "xsel", "--nodetach", "-i", "-b" },
      ["*"] = { "xsel", "--nodetach", "-i", "-p" },
    },
    paste = {
      ["+"] = { "xsel", "-o", "-b" },
      ["*"] = { "xsel", "-o", "-p" },
    },
    cache_enabled = 1,
  }
end

opt.cmdheight = 0
opt.completeopt = { "menu", "menuone", "noselect" }
opt.confirm = true
opt.copyindent = true
opt.cursorline = false
opt.diffopt:append { "algorithm:histogram", "linematch:60" }
opt.expandtab = true
opt.fillchars = { eob = " " }
opt.ignorecase = true
opt.infercase = true
opt.jumpoptions = ""
opt.laststatus = 3
opt.linebreak = true
opt.mouse = ""
opt.number = true
opt.preserveindent = true
opt.pumheight = 10
opt.relativenumber = true
opt.scrolloff = 3
opt.shiftround = true
opt.shiftwidth = 4
opt.shortmess:append { s = true, I = true, c = true, C = true }
opt.showcmd = true
opt.showcmdloc = "statusline"
opt.showmode = false
opt.showtabline = 0
opt.signcolumn = "yes"
opt.smartcase = true
opt.softtabstop = 4
opt.spell = false
opt.splitbelow = true
opt.splitright = true
opt.tabstop = 4
opt.termguicolors = true
opt.timeoutlen = 500
opt.title = true
opt.undofile = true
opt.updatetime = 300
opt.virtualedit = "block"
opt.wrap = false
opt.writebackup = false

if vim.fn.has "nvim-0.11" == 1 then opt.tabclose = "uselast" end

vim.g.markdown_recommended_style = 0

if not vim.t.bufs then vim.t.bufs = vim.api.nvim_list_bufs() end
