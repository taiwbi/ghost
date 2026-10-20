local M = {}
local contexts = require "util.minuet_context"

local installed = setmetatable({}, { __mode = "k" })

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
