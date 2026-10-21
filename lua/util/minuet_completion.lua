local M = {}
local contexts = require "util.minuet_context"

local installed = setmetatable({}, { __mode = "k" })

local function node_issues(root, bufnr)
  local issues = {}

  local function visit(node)
    local missing = node:missing()
    if missing or node:type() == "ERROR" then
      local _, _, _, _, start_byte, end_byte = node:range(true)
      local text = missing and "" or vim.treesitter.get_node_text(node, bufnr)
      issues[table.concat({ node:type(), start_byte, end_byte, missing and "missing" or "error", text }, "\0")] = {
        start_byte = start_byte,
        end_byte = end_byte,
        type = node:type(),
        missing = missing,
        text = text,
      }
    end

    for child in node:iter_children() do
      visit(child)
    end
  end

  visit(root)
  return issues
end

local function issue_key(issue, start_byte, end_byte)
  return table.concat({ issue.type, start_byte, end_byte, issue.missing and "missing" or "error", issue.text }, "\0")
end

local function validation_snapshot(context)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  if not context.lines_before or context.lines_before:match "[^\n]*$" ~= line:sub(1, col) then return end
  if (context.lines_after or ""):match "^[^\n]*" ~= line:sub(col + 1) then return end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then return end
  local parsed, trees = pcall(parser.parse, parser)
  if not parsed or not trees or not trees[1] then return end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local offset = col
  for i = 1, row do
    offset = offset + #(lines[i] or "") + 1
  end

  local root = trees[1]:root()
  return {
    lines = lines,
    row = row,
    col = col,
    offset = offset,
    filetype = vim.bo[bufnr].filetype,
    language = parser:lang(),
    issues = node_issues(root, bufnr),
  }
end

local function parses_without_new_issues(text, snapshot)
  local source = table.concat(snapshot.lines, "\n")
  local candidate = source:sub(1, snapshot.offset) .. text .. source:sub(snapshot.offset + 1)
  local insert_start = snapshot.offset
  local insert_end = insert_start + #text
  local scratch = vim.api.nvim_create_buf(false, true)

  local ok, valid = pcall(function()
    vim.bo[scratch].buftype = "nofile"
    vim.bo[scratch].bufhidden = "wipe"
    vim.bo[scratch].swapfile = false
    vim.bo[scratch].filetype = snapshot.filetype
    vim.api.nvim_buf_set_lines(scratch, 0, -1, false, vim.split(candidate, "\n", { plain = true }))

    local parser = vim.treesitter.get_parser(scratch, snapshot.language)
    local trees = parser:parse()
    if not trees or not trees[1] then return false end

    for _, issue in pairs(node_issues(trees[1]:root(), scratch)) do
      local start_byte, end_byte = issue.start_byte, issue.end_byte
      local in_inserted_text = start_byte < insert_end and end_byte > insert_start
      if start_byte == end_byte and start_byte >= insert_start and start_byte <= insert_end then
        in_inserted_text = true
      end

      if not in_inserted_text then
        if start_byte >= insert_end then
          start_byte, end_byte = start_byte - #text, end_byte - #text
        elseif end_byte > insert_start then
          -- An error spanning the insertion cannot be inherited unchanged.
          return false
        end
      end

      if in_inserted_text or not snapshot.issues[issue_key(issue, start_byte, end_byte)] then return false end
    end
    return true
  end)

  if vim.api.nvim_buf_is_valid(scratch) then vim.api.nvim_buf_delete(scratch, { force = true }) end
  return ok and valid == true
end

local function keep_parseable_prefix(text, snapshot)
  if not snapshot then return text end
  local ok, valid = pcall(parses_without_new_issues, text, snapshot)
  if not ok then return text end
  if valid then return text end

  for newline = #text, 1, -1 do
    if text:sub(newline, newline) == "\n" then
      local finish = newline - 1
      if text:sub(finish, finish) == "\r" then finish = finish - 1 end
      local prefix = text:sub(1, finish)
      if prefix:find "%S" then
        local checked, prefix_valid = pcall(parses_without_new_issues, prefix, snapshot)
        if checked and prefix_valid then return prefix end
      end
    end
  end
end

-- The first suffix line is only the remainder of the cursor's current line.
-- Anchor on the next two nonblank lines, keeping their indentation and blanks.
local function suffix_block(context)
  local lines = vim.split(context.lines_after or "", "\n", { plain = true })
  local last = #lines
  if context.opts and context.opts.is_incomplete_after then last = last - 1 end

  local first, count = nil, 0
  for i = 2, last do
    if lines[i]:find "%S" then
      first = first or i
      count = count + 1
      if count == 2 then return table.concat(lines, "\n", first, i) end
    end
  end
end

local function block_start(text, block)
  local start = 1
  while true do
    local first, last = text:find(block, start, true)
    if not first then return end
    local starts_line = first == 1 or text:sub(first - 1, first - 1) == "\n"
    local ends_line = last == #text or text:sub(last + 1, last + 1) == "\n"
    if starts_line and ends_line then return first end
    start = first + 1
  end
end

local function trim_overlap(text, after)
  for length = math.min(#text, #after), 15, -1 do
    local overlap = after:sub(1, length)
    if text:sub(-length) == overlap and vim.fn.strchars(overlap) >= 15 then return text:sub(1, #text - length) end
  end
  return text
end

---Keep useful FIM text before it starts copying the immediate suffix context.
---@param text string?
---@param context table?
---@return string?
function M.filter(text, context)
  if type(text) ~= "string" then return end
  context = context or {}
  text = contexts.filter(text, context.scope)
  local after = context.lines_after or ""
  local block = suffix_block(context)
  local first = block and block_start(text, block)

  if first then
    -- Remove the separator newline as well, so accepting adds no blank line.
    local finish = first - 1
    if text:sub(finish, finish) == "\n" then finish = finish - 1 end
    text = text:sub(1, finish)

    -- Once the following block is confirmed duplicated, an existing quote or
    -- other current-line remainder may also have been copied before that block.
    local remainder = after:match "^[^\n]*"
    if remainder:find "%S" and text:sub(-#remainder) == remainder then text = text:sub(1, #text - #remainder) end
  end

  text = trim_overlap(text, after)
  -- Reuse a space already typed after inline content. A whitespace-only
  -- cursor line is indentation, so leave its completion spacing untouched.
  local before_line = (context.lines_before or ""):match "[^\n]*$"
  if before_line:sub(-1) == " " and before_line:find "%S" then text = text:gsub("^ +", "") end
  text = keep_parseable_prefix(text, context.validation)
  if not text then return end
  if text:find "%S" then return text end
end

---Wrap only the FIM completion provider; Duet uses a separate backend.
function M.install()
  local provider = require "minuet.backends.openai_fim_compatible"
  if installed[provider] == provider.complete then return end

  local complete = provider.complete
  provider.complete = function(context, callback)
    -- Capture request context before asynchronous results arrive. Never read
    -- the current buffer here: it may have changed or no longer be active.
    local snapshot = {
      lines_before = context.lines_before,
      lines_after = context.lines_after,
      scope = contexts.capture(context),
      validation = validation_snapshot(context),
      opts = { is_incomplete_after = context.opts and context.opts.is_incomplete_after },
    }
    return complete(context, function(items)
      if not items then return callback(items) end
      local filtered = {}
      for _, item in ipairs(items) do
        local text = M.filter(item, snapshot)
        if text then filtered[#filtered + 1] = text end
      end
      return callback(filtered)
    end)
  end
  installed[provider] = provider.complete
end

return M
