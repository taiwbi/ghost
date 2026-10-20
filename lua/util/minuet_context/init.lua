local M = {}
local rules = {}

---Register a context rule. Reusing a name replaces it without changing order.
---detect(info) returns plain state or nil; filter(text, state) never reads buffers.
function M.register(rule)
  assert(type(rule.name) == "string" and type(rule.detect) == "function" and type(rule.filter) == "function")
  for i, existing in ipairs(rules) do
    if existing.name == rule.name then
      rules[i] = rule
      return
    end
  end
  rules[#rules + 1] = rule
end

function M.unregister(name)
  for i, rule in ipairs(rules) do
    if rule.name == name then return table.remove(rules, i) end
  end
end

local function syntax_info(context)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local line = vim.api.nvim_get_current_line()
  -- Do not attach syntax from a different buffer/cursor to an old request.
  if not context.lines_before or context.lines_before:match "[^\n]*$" ~= line:sub(1, col) then return end
  if (context.lines_after or ""):match "^[^\n]*" ~= line:sub(col + 1) then return end

  local parser = vim.treesitter.get_parser(bufnr)
  if not parser then return end
  parser:parse { row, row + 1 }
  local range = { row, col, row, col }
  local language = parser:language_for_range(range)
  local tree = language:tree_for_range(range, { ignore_injections = true })
  if not tree then return end
  local info = {
    bufnr = bufnr,
    row = row,
    col = col,
    offset = vim.api.nvim_buf_get_offset(bufnr, row) + col,
    language = language:lang(),
    node = tree:root():named_descendant_for_range(unpack(range)),
    request = context,
  }
  function info.text(node) return vim.treesitter.get_node_text(node, bufnr) end
  function info.contains(node)
    local _, _, first = node:start()
    local _, _, last = node:end_()
    return first <= info.offset and info.offset <= last
  end
  local captures
  function info.captures()
    if captures then return captures end
    captures = {}
    -- Read queries directly: detection must also work without highlighting.
    local query = vim.treesitter.query.get(info.language, "highlights")
    if query then
      for id, node in query:iter_captures(tree:root(), bufnr, row, row + 1) do
        if info.contains(node) then captures[#captures + 1] = { name = query.captures[id], node = node } end
      end
    end
    return captures
  end
  return info
end

---Capture the first applicable rule before the asynchronous provider request.
function M.capture(context)
  local ok, info = pcall(syntax_info, context)
  if not ok or not info then return end
  for _, rule in ipairs(rules) do
    local detected, state = pcall(rule.detect, info)
    if detected and state then
      local copied, snapshot = pcall(vim.deepcopy, state)
      if copied then return { name = rule.name, state = snapshot, filter = rule.filter } end
    end
  end
end

---Apply captured state only; parser failures or broken rules leave text intact.
function M.filter(text, scope)
  if not scope then return text end
  local ok, result = pcall(scope.filter, text, scope.state)
  if ok and result == nil then return "" end
  if ok and type(result) == "string" then return result end
  return text
end

M.register(require "util.minuet_context.strings")

return M
