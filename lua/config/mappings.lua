local buffer = require "util.buffer"
local toggles = require "util.toggles"

local map = function(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function picker() return require("snacks").picker end
local function snacks() return require "snacks" end

local function lazy_load(plugin)
  return function() require("lazy").load { plugins = { plugin } } end
end

-- General ---------------------------------------------------------------------

map("n", "H", "^", { desc = "Go to start of line" })
map("n", "L", "$", { desc = "Go to end of line" })
map("v", "H", "^", { desc = "Go to start of line" })
map("v", "L", "$", { desc = "Go to end of line" })

map("n", "<C-s>", "<Cmd>silent! update<CR>", { desc = "Force write" })
map("n", "<C-q>", "<Cmd>confirm qall<CR>", { desc = "Force quit" })
map("n", "<Leader>n", "<Cmd>enew<CR>", { desc = "New file" })
map("n", "<Leader>w", function() vim.cmd "w" end, { desc = "Save" })
map("n", "<Leader>W", function() vim.cmd "noautocmd w" end, { desc = "Save without formatting" })
map("n", "<Leader>c", function() buffer.close() end, { desc = "Close buffer" })
map("n", "<Leader>C", function() buffer.close(0, true) end, { desc = "Force close buffer" })
map("n", "<Leader>R", function() snacks().rename.rename_file() end, { desc = "Rename current file" })

map("n", "<Leader>Q", function() vim.cmd "q" end, { desc = "Quit" })
map("n", "<Leader>q", function() vim.cmd "q" end, { desc = "Quit" })

map("n", "]t", "<Cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "[t", "<Cmd>tabprevious<CR>", { desc = "Previous tab" })

map("n", "\\", "<Cmd>split<CR>", { desc = "Horizontal split" })
map("n", "|", "<Cmd>vsplit<CR>", { desc = "Vertical split" })

-- Horizontal Scroll
vim.keymap.set({ "n", "i", "v" }, "<S-ScrollWheelUp>", "3zh")
vim.keymap.set({ "n", "i", "v" }, "<S-ScrollWheelDown>", "3zl")

-- Window navigation (smart-splits aware)
local function smart_split(action, fallback)
  return function()
    local ok, ss = pcall(require, "smart-splits")
    if ok and ss[action] then
      ss[action]()
    else
      vim.cmd(fallback)
    end
  end
end
map("n", "<C-h>", smart_split("move_cursor_left", "wincmd h"), { desc = "Window left" })
map("n", "<C-j>", smart_split("move_cursor_down", "wincmd j"), { desc = "Window down" })
map("n", "<C-k>", smart_split("move_cursor_up", "wincmd k"), { desc = "Window up" })
map("n", "<C-l>", smart_split("move_cursor_right", "wincmd l"), { desc = "Window right" })

map("n", "<C-Up>", smart_split("resize_up", "resize +2"), { desc = "Resize up" })
map("n", "<C-Down>", smart_split("resize_down", "resize -2"), { desc = "Resize down" })
map("n", "<C-Left>", smart_split("resize_left", "vertical resize -2"), { desc = "Resize left" })
map("n", "<C-Right>", smart_split("resize_right", "vertical resize +2"), { desc = "Resize right" })

-- Buffer nav and management
map("n", "<Tab>", function() buffer.nav(vim.v.count1) end, { desc = "Next buffer" })
map("n", "<S-Tab>", function() buffer.nav(-vim.v.count1) end, { desc = "Previous buffer" })
map("n", "]b", function() buffer.nav(vim.v.count1) end, { desc = "Next buffer" })
map("n", "[b", function() buffer.nav(-vim.v.count1) end, { desc = "Previous buffer" })
map("n", ">b", function() buffer.move(vim.v.count1) end, { desc = "Move buffer right" })
map("n", "<b", function() buffer.move(-vim.v.count1) end, { desc = "Move buffer left" })

map("n", "<Leader>bb", function() picker().buffers() end, { desc = "Navigate to buffer" })
map("n", "<Leader>bc", function() buffer.close_all(true) end, { desc = "Close all buffers except current" })
map("n", "<Leader>bC", function() buffer.close_all() end, { desc = "Close all buffers" })
map("n", "<Leader>bd", function()
  picker().buffers {
    actions = {
      delete = function(p, item) snacks().bufdelete { buf = item.buf } end,
    },
    win = { input = { keys = { ["<C-d>"] = { "delete", mode = { "n", "i" } } } } },
  }
end, { desc = "Delete a buffer" })
map("n", "<Leader>bl", function() buffer.close_left() end, { desc = "Close buffers to the left" })
map("n", "<Leader>bp", "<C-^>", { desc = "Go to previous buffer" })
map("n", "<Leader>br", function() buffer.close_right() end, { desc = "Close buffers to the right" })

map("n", "<Leader>bse", function() buffer.sort "extension" end, { desc = "Sort by extension" })
map("n", "<Leader>bsi", function() buffer.sort "bufnr" end, { desc = "Sort by buffer number" })
map("n", "<Leader>bsm", function() buffer.sort "modified" end, { desc = "Sort by last modified" })
map("n", "<Leader>bsp", function() buffer.sort "full_path" end, { desc = "Sort by full path" })
map("n", "<Leader>bsr", function() buffer.sort "relative_path" end, { desc = "Sort by relative path" })

map("n", "<Leader>b\\", function()
  picker().buffers {
    confirm = function(p, item)
      p:close()
      vim.cmd "split"
      vim.api.nvim_set_current_buf(item.buf)
    end,
  }
end, { desc = "Open buffer in horizontal split" })
map("n", "<Leader>b|", function()
  picker().buffers {
    confirm = function(p, item)
      p:close()
      vim.cmd "vsplit"
      vim.api.nvim_set_current_buf(item.buf)
    end,
  }
end, { desc = "Open buffer in vertical split" })

-- List management -------------------------------------------------------------

map("n", "<Leader>xq", "<Cmd>copen<CR>", { desc = "Open quickfix list" })
map("n", "]q", "<Cmd>cnext<CR>", { desc = "Next quickfix entry" })
map("n", "[q", "<Cmd>cprev<CR>", { desc = "Previous quickfix entry" })
map("n", "]Q", "<Cmd>clast<CR>", { desc = "Last quickfix entry" })
map("n", "[Q", "<Cmd>cfirst<CR>", { desc = "First quickfix entry" })

map("n", "<Leader>xl", "<Cmd>lopen<CR>", { desc = "Open location list" })
map("n", "]l", "<Cmd>lnext<CR>", { desc = "Next location entry" })
map("n", "[l", "<Cmd>lprev<CR>", { desc = "Previous location entry" })
map("n", "]L", "<Cmd>llast<CR>", { desc = "Last location entry" })
map("n", "[L", "<Cmd>lfirst<CR>", { desc = "First location entry" })

-- Explorer (snacks) -----------------------------------------------------------

map("n", "<Leader>e", function() snacks().explorer() end, { desc = "Toggle explorer" })
map("n", "<Leader>o", function() snacks().explorer { focus = "input" } end, { desc = "Focus explorer" })

-- Dashboard -------------------------------------------------------------------

map("n", "<Leader>h", function()
  if vim.bo.filetype == "snacks_dashboard" then
    buffer.close()
  else
    snacks().dashboard()
  end
end, { desc = "Home screen" })

-- Session ---------------------------------------------------------------------

local function resession() return require "resession" end
map("n", "<Leader>Ss", function()
  vim.ui.input({ prompt = "Save session as: " }, function(name)
    if name and name ~= "" then resession().save(name) end
  end)
end, { desc = "Save session" })
map("n", "<Leader>Sl", function() resession().load "Last Session" end, { desc = "Load last session" })
map("n", "<Leader>Sd", function() resession().delete() end, { desc = "Delete session" })
map(
  "n",
  "<Leader>SD",
  function() resession().delete(nil, { dir = "dirsession" }) end,
  { desc = "Delete directory session" }
)
map("n", "<Leader>Sf", function() resession().load() end, { desc = "Find session" })
map(
  "n",
  "<Leader>SF",
  function() resession().load(nil, { dir = "dirsession" }) end,
  { desc = "Find directory session" }
)
map("n", "<Leader>S.", function() resession().load(vim.fn.getcwd(), { dir = "dirsession" }) end, {
  desc = "Load current directory session",
})

-- Package management ----------------------------------------------------------

map("n", "<Leader>pa", function()
  vim.cmd "Lazy update"
  vim.cmd "MasonToolsUpdate"
end, { desc = "Update Lazy and Mason" })
map("n", "<Leader>pi", "<Cmd>Lazy install<CR>", { desc = "Plugins install" })
map("n", "<Leader>pm", "<Cmd>Mason<CR>", { desc = "Mason installer" })
map("n", "<Leader>pM", "<Cmd>MasonUpdate<CR>", { desc = "Mason updater" })
map("n", "<Leader>ps", "<Cmd>Lazy<CR>", { desc = "Plugins status" })
map("n", "<Leader>pS", "<Cmd>Lazy sync<CR>", { desc = "Plugins sync" })
map("n", "<Leader>pu", "<Cmd>Lazy check<CR>", { desc = "Plugins check for updates" })
map("n", "<Leader>pU", "<Cmd>Lazy update<CR>", { desc = "Plugins update" })

-- LSP -------------------------------------------------------------------------

map("n", "<Leader>li", "<Cmd>LspInfo<CR>", { desc = "LSP info" })
map("n", "K", vim.lsp.buf.hover, { desc = "LSP hover" })
map("n", "<Leader>lI", "<Cmd>NullLsInfo<CR>", { desc = "None-ls info" })
map("n", "<Leader>lf", function() vim.lsp.buf.format { async = true } end, { desc = "Format document" })
map("n", "<Leader>lS", "<Cmd>AerialToggle<CR>", { desc = "Symbols outline" })
map("n", "<Leader>lh", vim.lsp.buf.signature_help, { desc = "Signature help" })
map("n", "<Leader>la", vim.lsp.buf.code_action, { desc = "Code actions" })
map("v", "<Leader>la", vim.lsp.buf.code_action, { desc = "Code actions" })
map("n", "<Leader>lA", function() vim.lsp.buf.code_action { context = { only = { "source" }, diagnostics = {} } } end, {
  desc = "Source code actions",
})
map("n", "<Leader>lr", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<Leader>ld", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "gl", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<Leader>lb", function() picker().diagnostics_buffer() end, { desc = "Buffer diagnostics" })
map("n", "<Leader>lD", function() picker().diagnostics() end, { desc = "All diagnostics" })
if vim.fn.has "nvim-0.12" == 1 then
  map("n", "<Leader>lw", function() vim.diagnostic.setqflist { open = true } end, { desc = "Workspace diagnostics" })
end
map("n", "<Leader>ls", function() picker().lsp_symbols() end, { desc = "Document symbols" })
map("n", "<Leader>lG", function() picker().lsp_workspace_symbols() end, { desc = "Workspace symbols" })
map("n", "<Leader>lR", function() picker().lsp_references() end, { desc = "References" })

map("n", "]d", function() vim.diagnostic.jump { count = 1, float = true } end, { desc = "Next diagnostic" })
map("n", "[d", function() vim.diagnostic.jump { count = -1, float = true } end, { desc = "Previous diagnostic" })
map(
  "n",
  "]e",
  function() vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.ERROR, float = true } end,
  { desc = "Next error" }
)
map(
  "n",
  "[e",
  function() vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR, float = true } end,
  { desc = "Previous error" }
)
map(
  "n",
  "]w",
  function() vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.WARN, float = true } end,
  { desc = "Next warning" }
)
map(
  "n",
  "[w",
  function() vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.WARN, float = true } end,
  { desc = "Previous warning" }
)

map("n", "]y", "<Cmd>AerialNext<CR>", { desc = "Next document symbol" })
map("n", "[y", "<Cmd>AerialPrev<CR>", { desc = "Previous document symbol" })

map("n", "gy", vim.lsp.buf.type_definition, { desc = "Type definition" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })

-- Debugger --------------------------------------------------------------------

local function dap() return require "dap" end
local function dapui() return require "dapui" end

map("n", "<Leader>dc", function() dap().continue() end, { desc = "Start/continue debugger" })
map("n", "<F5>", function() dap().continue() end, { desc = "Start/continue debugger" })
map("n", "<Leader>dp", function() dap().pause() end, { desc = "Pause debugger" })
map("n", "<F6>", function() dap().pause() end, { desc = "Pause debugger" })
map("n", "<Leader>dr", function() dap().restart_frame() end, { desc = "Restart debugger" })
map("n", "<C-F5>", function() dap().restart_frame() end, { desc = "Restart debugger" })
map("n", "<Leader>ds", function() dap().run_to_cursor() end, { desc = "Run to cursor" })
map("n", "<Leader>dq", function() dap().close() end, { desc = "Close debugger session" })
map("n", "<Leader>dQ", function() dap().terminate() end, { desc = "Terminate debugger" })
map("n", "<S-F5>", function() dap().terminate() end, { desc = "Terminate debugger" })
map("n", "<Leader>db", function() dap().toggle_breakpoint() end, { desc = "Toggle breakpoint" })
map("n", "<F9>", function() dap().toggle_breakpoint() end, { desc = "Toggle breakpoint" })
map("n", "<Leader>dB", function() dap().clear_breakpoints() end, { desc = "Clear breakpoints" })
map("n", "<Leader>dC", function()
  vim.ui.input({ prompt = "Condition: " }, function(cond)
    if cond then dap().set_breakpoint(cond) end
  end)
end, { desc = "Conditional breakpoint" })
map("n", "<Leader>do", function() dap().step_over() end, { desc = "Step over" })
map("n", "<F10>", function() dap().step_over() end, { desc = "Step over" })
map("n", "<Leader>di", function() dap().step_into() end, { desc = "Step into" })
map("n", "<F11>", function() dap().step_into() end, { desc = "Step into" })
map("n", "<Leader>dO", function() dap().step_out() end, { desc = "Step out" })
map("n", "<S-F11>", function() dap().step_out() end, { desc = "Step out" })
map("n", "<Leader>dE", function()
  vim.ui.input({ prompt = "Expression: " }, function(expr)
    if expr then dapui().eval(expr, { enter = true }) end
  end)
end, { desc = "Evaluate expression" })
map("v", "<Leader>dE", function() dapui().eval() end, { desc = "Evaluate expression" })
map("n", "<Leader>dR", function() dap().repl.toggle() end, { desc = "Toggle REPL" })
map("n", "<Leader>du", function() dapui().toggle() end, { desc = "Toggle debugger UI" })
map("n", "<Leader>dh", function() require("dap.ui.widgets").hover() end, { desc = "Debugger hover" })

-- Picker (snacks) -------------------------------------------------------------

map("n", "<Leader>f<CR>", function() picker().resume() end, { desc = "Resume previous search" })
map("n", "<Leader>f'", function() picker().marks() end, { desc = "Find marks" })
map(
  "n",
  "<Leader>fa",
  function() picker().files { dirs = { vim.fn.stdpath "config" } } end,
  { desc = "Find config files" }
)
map("n", "<Leader>fb", function() picker().buffers() end, { desc = "Find buffers" })
map("n", "<Leader>fc", function() picker().grep_word() end, { desc = "Find word under cursor" })
map("n", "<Leader>fC", function() picker().commands() end, { desc = "Find commands" })
map(
  "n",
  "<Leader>ff",
  function() picker().files { hidden = vim.tbl_get((vim.uv or vim.loop).fs_stat ".git" or {}, "type") == "directory" } end,
  { desc = "Find files" }
)
map("n", "<Leader>fF", function() picker().files { hidden = true, ignored = true } end, { desc = "Find all files" })
map("n", "<Leader>fg", function() picker().git_files() end, { desc = "Find git files" })
map("n", "<Leader>fh", function() picker().help() end, { desc = "Find help tags" })
map("n", "<Leader>fk", function() picker().keymaps() end, { desc = "Find keymaps" })
map("n", "<Leader>fl", function() picker().lines() end, { desc = "Find lines" })
map("n", "<Leader>fm", function() picker().man() end, { desc = "Find man pages" })
map("n", "<Leader>fn", function() picker().notifications() end, { desc = "Find notifications" })
map("n", "<Leader>fo", function() picker().recent() end, { desc = "Find old files" })
map("n", "<Leader>fO", function() picker().recent { filter = { cwd = true } } end, {
  desc = "Find old files (cwd)",
})
map("n", "<Leader>fp", function() picker().projects() end, { desc = "Find projects" })
map("n", "<Leader>fr", function() picker().registers() end, { desc = "Find registers" })
map("n", "<Leader>fs", function() picker().smart() end, { desc = "Find smart (buffers/recent/files)" })
map("n", "<Leader>ft", function() picker().colorschemes() end, { desc = "Find colorschemes" })
map("n", "<Leader>fu", function() picker().undo() end, { desc = "Find undo history" })
if vim.fn.executable "rg" == 1 then
  map("n", "<Leader>fw", function() picker().grep() end, { desc = "Live grep" })
  map("n", "<Leader>fW", function() picker().grep { hidden = true, ignored = true } end, {
    desc = "Live grep (all files)",
  })
end

if vim.fn.executable "git" == 1 then
  map("n", "<Leader>gb", function() picker().git_branches() end, { desc = "Git branches" })
  map("n", "<Leader>gc", function() picker().git_log() end, { desc = "Git commits (repository)" })
  map("n", "<Leader>gC", function() picker().git_log { current_file = true, follow = true } end, {
    desc = "Git commits (current file)",
  })
  map("n", "<Leader>go", function() snacks().gitbrowse() end, { desc = "Git browse (open)" })
  map("x", "<Leader>go", function() snacks().gitbrowse() end, { desc = "Git browse (open)" })
  map("n", "<Leader>gt", function() picker().git_status() end, { desc = "Git status" })
  map("n", "<Leader>gT", function() picker().git_stash() end, { desc = "Git stash" })
end

-- Terminal (external only) ----------------------------------------------------

map("n", "<Leader>tg", function()
  local cwd = vim.fn.getcwd()
  os.execute("ghostty --working-directory=" .. vim.fn.shellescape(cwd) .. " > /dev/null 2>&1 &")
end, { desc = "Open kitty in directory" })

-- UI/UX toggles ---------------------------------------------------------------

map("n", "<Leader>ua", toggles.autopairs, { desc = "Toggle autopairs" })
map("n", "<Leader>ub", toggles.background, { desc = "Toggle background" })
map("n", "<Leader>uc", function() toggles.completion_buf() end, { desc = "Toggle autocompletion (buffer)" })
map("n", "<Leader>uC", toggles.completion_global, { desc = "Toggle autocompletion (global)" })
map("n", "<Leader>ud", toggles.diagnostics, { desc = "Toggle diagnostics" })
map("n", "<Leader>uD", toggles.dismiss_notifications, { desc = "Dismiss notifications" })
map("n", "<Leader>uf", function() toggles.autoformat_buf() end, { desc = "Toggle autoformat (buffer)" })
map("n", "<Leader>uF", toggles.autoformat_global, { desc = "Toggle autoformat (global)" })
map("n", "<Leader>ug", toggles.signcolumn, { desc = "Toggle signcolumn" })
map("n", "<Leader>uh", function() toggles.inlay_hints() end, { desc = "Toggle inlay hints (buffer)" })
map("n", "<Leader>uH", function() toggles.inlay_hints(0) end, { desc = "Toggle inlay hints (global)" })
map("n", "<Leader>ui", toggles.indent, { desc = "Toggle indent setting" })
map("n", "<Leader>u|", toggles.indent_guides, { desc = "Toggle indent guides" })
map("n", "<Leader>ul", toggles.statusline, { desc = "Toggle statusline" })
map("n", "<Leader>uL", toggles.codelens, { desc = "Toggle codelens" })
map("n", "<Leader>un", toggles.number, { desc = "Change line numbering" })
map("n", "<Leader>uN", toggles.notifications, { desc = "Toggle notifications" })
map("n", "<Leader>up", toggles.paste, { desc = "Toggle paste mode" })
map("n", "<Leader>ur", toggles.reference_highlight, { desc = "Toggle reference highlighting" })
map("n", "<Leader>us", toggles.spell, { desc = "Toggle spellcheck" })
map("n", "<Leader>uS", toggles.conceal, { desc = "Toggle conceal" })
map("n", "<Leader>ut", toggles.tabline, { desc = "Toggle tabline" })
map("n", "<Leader>uu", toggles.url_highlight, { desc = "Toggle URL highlighting" })
map("n", "<Leader>uv", toggles.virtual_text, { desc = "Toggle diagnostics virtual text" })
map("n", "<Leader>uV", toggles.virtual_lines, { desc = "Toggle diagnostics virtual lines" })
map("n", "<Leader>uw", toggles.wrap, { desc = "Toggle wrap" })
map("n", "<Leader>uy", function() toggles.buffer_syntax() end, { desc = "Toggle syntax highlighting (buffer)" })
map(
  "n",
  "<Leader>uY",
  function() toggles.buffer_semantic_tokens() end,
  { desc = "Toggle LSP semantic tokens (buffer)" }
)
map("n", "<Leader>uz", toggles.color_highlight, { desc = "Toggle color highlighting" })
map("n", "<Leader>uZ", toggles.zen_mode, { desc = "Toggle zen mode" })

-- Helpers ---------------------------------------------------------------------

map("n", "<Leader>ra", function() vim.fn.setreg("+", vim.fn.expand "%:p") end, { desc = "Copy file's absolute path" })
map("n", "<Leader>rr", function() vim.fn.setreg("+", vim.fn.expand "%:.") end, { desc = "Copy file's relative path" })

-- Database --------------------------------------------------------------------

map("n", "<Leader>Db", "<Cmd>DBUIToggle<CR>", { desc = "Toggle database UI" })

-- Clipboard / Paste -----------------------------------------------------------

map("n", "<C-S-v>", '"+p', { desc = "Paste from clipboard" })
map("v", "<C-S-v>", '"+p', { desc = "Paste from clipboard" })
map("i", "<C-S-v>", "<C-r>+", { desc = "Paste from clipboard" })
map("c", "<C-S-v>", "<C-r>+", { desc = "Paste from clipboard" })
map("t", "<C-S-v>", [[<C-\><C-n>"+pi]], { desc = "Paste from clipboard" })

-- Visual mode tweaks ----------------------------------------------------------

map("v", "<Leader>p", '"_dP', { desc = "Paste without overwriting clipboard" })
map("v", "<Leader>x", '"_x', { desc = "Delete without overwriting clipboard" })
map("v", "<", "<gv", { desc = "Unindent line" })
map("v", ">", ">gv", { desc = "Indent line" })

-- Yank entire file ------------------------------------------------------------

map("n", "yag", function()
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd "normal! ggVGy"
  vim.api.nvim_win_set_cursor(0, pos)
end, { desc = "Yank entire file (preserve position)" })

-- Neovide scale factor --------------------------------------------------------

map("n", "<C-0>", function()
  if vim.g.neovide_scale_factor then vim.g.neovide_scale_factor = 1 end
end, { desc = "Reset Neovide scale factor" })
map("n", "<C-+>", function()
  if vim.g.neovide_scale_factor then vim.g.neovide_scale_factor = math.min(vim.g.neovide_scale_factor + 0.1, 2.0) end
end, { desc = "Increase Neovide scale factor" })
map("n", "<C-_>", function()
  if vim.g.neovide_scale_factor then vim.g.neovide_scale_factor = math.max(vim.g.neovide_scale_factor - 0.1, 0.5) end
end, { desc = "Decrease Neovide scale factor" })
