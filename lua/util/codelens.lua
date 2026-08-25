local M = {}

local original_set_extmark
local shiftwidths = {}
local line_indents = {}
local active_scopes = {}
local scope_listener

local function cache_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local shiftwidth = vim.bo[bufnr].shiftwidth
  shiftwidths[bufnr] = shiftwidth > 0 and shiftwidth or vim.bo[bufnr].tabstop

  local tabstop = vim.bo[bufnr].tabstop
  local indents = {}
  for row, text in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local width = 0
    for char in text:match("^%s*"):gmatch "." do
      width = char == "\t" and width + tabstop - (width % tabstop) or width + 1
    end
    indents[row - 1] = width
  end
  line_indents[bufnr] = indents
end

local function guide_highlight(bufnr, row, col)
  local scope = active_scopes[bufnr]
  return scope and row + 1 >= scope.from and row + 1 <= scope.to and col == scope.indent and "SnacksIndentScope"
    or "SnacksIndent"
end

local function decorate_padding(bufnr, row, opts)
  local lines = opts.virt_lines
  local chunks = lines and lines[1]
  local padding = chunks and chunks[1]

  if
    not opts.virt_lines_above
    or not padding
    or type(padding[1]) ~= "string"
    or padding[2] ~= "LspCodeLensSeparator"
    or not padding[1]:match "^ +$"
  then
    return opts
  end

  -- CodeLens extmarks are created from a decoration provider, so buffer
  -- options cannot be queried here. They are cached by the autocmds below.
  local shiftwidth = shiftwidths[bufnr]
  local indent = line_indents[bufnr] and line_indents[bufnr][row]
  if not shiftwidth or shiftwidth <= 0 or indent == nil then return opts end

  local decorated = {}
  for col = 0, indent - 1 do
    decorated[#decorated + 1] = col % shiftwidth == 0 and { "▏", guide_highlight(bufnr, row, col) }
      or { " ", "LspCodeLensSeparator" }
  end
  vim.list_extend(decorated, chunks, 2)

  local virt_lines = { decorated }
  vim.list_extend(virt_lines, lines, 2)
  opts.virt_lines = virt_lines
  return opts
end

local function refresh_scope_highlights(bufnr)
  if not original_set_extmark or not vim.api.nvim_buf_is_valid(bufnr) then return end

  for name, ns_id in pairs(vim.api.nvim_get_namespaces()) do
    if name:match "^nvim%.lsp%.codelens:" then
      local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, { details = true })
      for _, mark in ipairs(marks) do
        local id, row, col, details = unpack(mark)
        local lines = details.virt_lines and vim.deepcopy(details.virt_lines)
        local chunks = lines and lines[1]
        local win_col = 0
        local changed = false

        for _, chunk in ipairs(chunks or {}) do
          if chunk[1] == "▏" and (chunk[2] == "SnacksIndent" or chunk[2] == "SnacksIndentScope") then
            local highlight = guide_highlight(bufnr, row, win_col)
            changed = changed or chunk[2] ~= highlight
            chunk[2] = highlight
          end
          win_col = win_col + vim.fn.strdisplaywidth(chunk[1])
        end

        if changed then
          original_set_extmark(bufnr, ns_id, row, col, {
            id = id,
            virt_lines = lines,
            virt_lines_above = details.virt_lines_above,
            virt_lines_overflow = details.virt_lines_overflow,
            hl_mode = details.hl_mode,
          })
        end
      end
    end
  end
end

function M.setup()
  if original_set_extmark then return end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    cache_buffer(bufnr)
  end

  local group = vim.api.nvim_create_augroup("codelens_indent_guides", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWinEnter", "FileType" }, {
    group = group,
    callback = function(args) cache_buffer(args.buf) end,
  })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(args) cache_buffer(args.buf) end,
  })
  vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = { "shiftwidth", "tabstop" },
    callback = function(args) cache_buffer(args.buf) end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args)
      shiftwidths[args.buf] = nil
      line_indents[args.buf] = nil
      active_scopes[args.buf] = nil
    end,
  })

  original_set_extmark = vim.api.nvim_buf_set_extmark
  vim.api.nvim_buf_set_extmark = function(bufnr, ns_id, line, col, opts)
    return original_set_extmark(bufnr, ns_id, line, col, decorate_padding(bufnr, line, opts))
  end

  scope_listener = Snacks.scope.attach(function(win, bufnr, scope)
    if win ~= vim.api.nvim_get_current_win() then return end
    active_scopes[bufnr] = scope
    refresh_scope_highlights(bufnr)
  end)
end

return M
