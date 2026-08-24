local opt = vim.opt

opt.backspace:append "nostop"
opt.breakindent = true
opt.clipboard = "unnamedplus"
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
opt.mouse = "a"
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
