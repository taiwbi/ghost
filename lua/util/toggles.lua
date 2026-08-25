local M = {}

local function bool2str(v) return v and "on" or "off" end
local function notify(msg) vim.notify(msg, vim.log.levels.INFO) end

function M.autopairs()
  local ok, autopairs = pcall(require, "nvim-autopairs")
  if not ok then return notify "autopairs not available" end
  if autopairs.state.disabled then
    autopairs.enable()
  else
    autopairs.disable()
  end
  notify(("autopairs %s"):format(bool2str(not autopairs.state.disabled)))
end

function M.background()
  vim.go.background = vim.go.background == "light" and "dark" or "light"
  notify(("background=%s"):format(vim.go.background))
end

function M.diagnostics()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  notify(("diagnostics %s"):format(bool2str(vim.diagnostic.is_enabled())))
end

local previous_virtual_text
function M.virtual_text()
  local current = vim.diagnostic.config().virtual_text
  local target = false
  if current then
    previous_virtual_text = current
  else
    target = previous_virtual_text or true
  end
  vim.diagnostic.config { virtual_text = target }
  notify(("virtual text %s"):format(bool2str(target ~= false)))
end

local previous_virtual_lines
function M.virtual_lines()
  local current = vim.diagnostic.config().virtual_lines
  local target = false
  if current then
    previous_virtual_lines = current
  else
    target = previous_virtual_lines or true
  end
  vim.diagnostic.config { virtual_lines = target }
  notify(("virtual lines %s"):format(bool2str(target ~= false)))
end

function M.signcolumn()
  local modes = { auto = "no", no = "yes", yes = "auto" }
  vim.wo.signcolumn = modes[vim.wo.signcolumn] or "yes"
  notify(("signcolumn=%s"):format(vim.wo.signcolumn))
end

local last_foldcolumn
function M.foldcolumn()
  local current = vim.wo.foldcolumn
  if current ~= "0" then last_foldcolumn = current end
  vim.wo.foldcolumn = current == "0" and (last_foldcolumn or "1") or "0"
  notify(("foldcolumn=%s"):format(vim.wo.foldcolumn))
end

function M.indent_guides()
  local snacks = package.loaded["snacks"]
  if snacks and snacks.indent then
    if snacks.indent.enabled then
      snacks.indent.disable()
    else
      snacks.indent.enable()
    end
    notify(("indent guides %s"):format(bool2str(snacks.indent.enabled)))
  else
    notify "indent guides not available"
  end
end

function M.statusline()
  local laststatus = vim.opt.laststatus:get()
  local next_status, label
  if laststatus == 0 then
    next_status, label = 2, "local"
  elseif laststatus == 2 then
    next_status, label = 3, "global"
  else
    next_status, label = 0, "off"
  end
  vim.opt.laststatus = next_status
  notify(("statusline %s"):format(label))
end

function M.tabline()
  vim.opt.showtabline = vim.opt.showtabline:get() == 0 and 2 or 0
  notify(("tabline %s"):format(bool2str(vim.opt.showtabline:get() == 2)))
end

function M.conceal()
  vim.opt.conceallevel = vim.opt.conceallevel:get() == 0 and 2 or 0
  notify(("conceal %s"):format(bool2str(vim.opt.conceallevel:get() == 2)))
end

function M.indent()
  local ok, input = pcall(vim.fn.input, "Set indent value (>0 expandtab, <=0 noexpandtab): ")
  if not ok then return end
  local n = tonumber(input)
  if not n or n == 0 then return end
  vim.bo.expandtab = n > 0
  n = math.abs(n)
  vim.bo.tabstop = n
  vim.bo.softtabstop = n
  vim.bo.shiftwidth = n
  notify(("indent=%d %s"):format(n, vim.bo.expandtab and "expandtab" or "noexpandtab"))
end

function M.number()
  local n, rn = vim.wo.number, vim.wo.relativenumber
  if not n and not rn then
    vim.wo.number = true
  elseif n and not rn then
    vim.wo.relativenumber = true
  elseif n and rn then
    vim.wo.number = false
  else
    vim.wo.relativenumber = false
  end
  notify(("number %s, relativenumber %s"):format(bool2str(vim.wo.number), bool2str(vim.wo.relativenumber)))
end

function M.spell()
  vim.wo.spell = not vim.wo.spell
  notify(("spell %s"):format(bool2str(vim.wo.spell)))
end

function M.paste()
  local paste = not vim.opt.paste:get()
  vim.opt.paste = paste
  notify(("paste %s"):format(bool2str(paste)))
end

function M.wrap()
  vim.wo.wrap = not vim.wo.wrap
  notify(("wrap %s"):format(bool2str(vim.wo.wrap)))
end

function M.buffer_syntax(bufnr)
  bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_win_get_buf(0)
  local ts_ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if vim.bo[bufnr].syntax == "off" then
    if ts_ok and parsers.has_parser() then vim.treesitter.start(bufnr) end
    vim.bo[bufnr].syntax = "on"
  else
    if ts_ok and parsers.has_parser() then vim.treesitter.stop(bufnr) end
    vim.bo[bufnr].syntax = "off"
  end
  notify(("syntax %s"):format(vim.bo[bufnr].syntax))
end

function M.buffer_semantic_tokens(bufnr)
  bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_win_get_buf(0)
  vim.b[bufnr].semantic_tokens = vim.b[bufnr].semantic_tokens == false
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if client.server_capabilities.semanticTokensProvider then
      vim.lsp.semantic_tokens[vim.b[bufnr].semantic_tokens and "start" or "stop"](bufnr, client.id)
    end
  end
  notify(("semantic tokens %s"):format(bool2str(vim.b[bufnr].semantic_tokens)))
end

function M.inlay_hints(bufnr)
  bufnr = (bufnr and bufnr ~= 0) and bufnr or nil
  local enabled = not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }
  vim.lsp.inlay_hint.enable(enabled, { bufnr = bufnr })
  notify(("inlay hints %s"):format(bool2str(enabled)))
end

function M.codelens()
  vim.g.codelens_enabled = not vim.g.codelens_enabled
  vim.lsp.codelens.enable(vim.g.codelens_enabled, { bufnr = 0 })
  notify(("codelens %s"):format(bool2str(vim.g.codelens_enabled)))
end

function M.autoformat_buf(bufnr)
  bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
  if vim.b[bufnr].autoformat == nil then vim.b[bufnr].autoformat = vim.g.autoformat ~= false end
  vim.b[bufnr].autoformat = not vim.b[bufnr].autoformat
  notify(("buffer autoformat %s"):format(bool2str(vim.b[bufnr].autoformat)))
end

function M.autoformat_global()
  vim.g.autoformat = vim.g.autoformat == false
  notify(("global autoformat %s"):format(bool2str(vim.g.autoformat)))
end

function M.completion_buf(bufnr)
  bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
  if vim.b[bufnr].completion == nil then vim.b[bufnr].completion = vim.g.completion ~= false end
  vim.b[bufnr].completion = not vim.b[bufnr].completion
  notify(("buffer completion %s"):format(bool2str(vim.b[bufnr].completion)))
end

function M.completion_global()
  vim.g.completion = vim.g.completion == false
  notify(("global completion %s"):format(bool2str(vim.g.completion)))
end

function M.notifications()
  vim.g.notifications_enabled = vim.g.notifications_enabled == false
  notify(("notifications %s"):format(bool2str(vim.g.notifications_enabled)))
end

function M.dismiss_notifications()
  local snacks = package.loaded["snacks"]
  if snacks and snacks.notifier then snacks.notifier.hide() end
end

function M.url_highlight()
  vim.g.highlighturl_enabled = vim.g.highlighturl_enabled == false
  notify(("URL highlighting %s"):format(bool2str(vim.g.highlighturl_enabled)))
end

function M.reference_highlight()
  local ok, illuminate = pcall(require, "illuminate")
  if not ok then return notify "vim-illuminate not available" end
  illuminate.toggle_buf()
  notify "toggled reference highlighting"
end

function M.color_highlight()
  local ok = pcall(vim.cmd, "HighlightColorsToggle")
  if not ok then notify "highlight colors not available" end
end

function M.zen_mode()
  local snacks = package.loaded["snacks"]
  if snacks and snacks.zen then snacks.zen() else notify "snacks.zen not available" end
end

return M
