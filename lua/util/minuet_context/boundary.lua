local M = {}

---Stop before a copied closing delimiter, respecting the context's escape rules.
---State: closing (string), escape (optional character), doubled (boolean), multiline (boolean).
function M.filter(text, state)
  local i, closing = 1, state.closing
  assert(type(closing) == "string" and #closing > 0, "closing delimiter must not be empty")
  -- A partial delimiter can combine with the existing one to close too early
  -- (for example, two generated quotes before an existing triple quote).
  local with_closing = text .. closing
  while i <= #text do
    local char = text:sub(i, i)
    if not state.multiline and (char == "\n" or char == "\r") then return text:sub(1, i - 1) end
    if with_closing:sub(i, i + #closing - 1) == closing then
      if state.doubled and text:sub(i + #closing, i + 2 * #closing - 1) == closing then
        i = i + 2 * #closing
      else
        return text:sub(1, i - 1)
      end
    elseif char == state.escape then
      local next_char = text:sub(i + 1, i + 1)
      if next_char == "" or (not state.multiline and (next_char == "\n" or next_char == "\r")) then
        return text:sub(1, i - 1)
      end
      i = i + 2
    else
      i = i + 1
    end
  end
  return text
end

return M
