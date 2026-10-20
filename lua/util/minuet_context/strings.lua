local M = { name = "string", filter = require("util.minuet_context.boundary").filter }

local function delimited(opening, closing, multiline, escape, doubled)
  return { opening = opening, closing = closing, multiline = multiline, escape = escape, doubled = doubled }
end

local function quoted(text, quotes, multiline, escape)
  local quote = text:sub(1, 1)
  if #quote == 1 and quotes:find(quote, 1, true) then return delimited(quote, quote, multiline, escape) end
end

local function ordinary(text) return quoted(text, "'\"", false, "\\") end

local function python(text)
  local prefix, quote = text:match "^([rRuUbBfF]*)(['\"])"
  if not quote then return end
  local triple = text:sub(#prefix + 1, #prefix + 3) == quote:rep(3)
  local closing = quote:rep(triple and 3 or 1)
  return delimited(prefix .. closing, closing, triple, "\\")
end

local function ecma(text) return quoted(text, "`", true, "\\") or ordinary(text) end

local function lua(text)
  local equals = text:match "^%[(=*)%["
  if equals then return delimited("[" .. equals .. "[", "]" .. equals .. "]", true) end
  return ordinary(text)
end

local function rust(text)
  local prefix, hashes = text:match '^([bc]?r)(#*)"'
  if prefix then return delimited(prefix .. hashes .. '"', '"' .. hashes, true) end
  local opening = text:match '^([bc]?")'
  if opening then return delimited(opening, '"', true, "\\") end
end

local function c(text)
  for _, prefix in ipairs { "u8", "u", "U", "L", "" } do
    local rest = text:sub(#prefix + 1)
    if text:sub(1, #prefix) == prefix then
      local tag = rest:match '^R"([^ ()\\\t\r\n]*)%('
      if tag then return delimited(prefix .. 'R"' .. tag .. "(", ")" .. tag .. '"', true) end
      if rest:sub(1, 1) == '"' then return delimited(prefix .. '"', '"', false, "\\") end
    end
  end
end

local function php(text)
  local prefix = text:match "^[bB]" or ""
  local form = quoted(text:sub(#prefix + 1), "'\"", true, "\\")
  if form then form.opening = prefix .. form.opening end
  return form
end

local function bash(text)
  if text:sub(1, 2) == "$'" then return delimited("$'", "'", true, "\\") end
  return quoted(text, "'", true) or quoted(text, '"', true, "\\")
end

local function sql(text)
  local prefix = text:match "^[eEnN]" or ""
  if text:sub(#prefix + 1, #prefix + 1) == "'" then
    return delimited(prefix .. "'", "'", true, prefix:lower() == "e" and "\\" or nil, true)
  end
end

-- Small form adapters; parser node names are discovered through @string captures.
-- Unknown languages/forms are left unrestricted until their quoting is defined.
M.languages = {
  python = python,
  javascript = ecma,
  typescript = ecma,
  tsx = ecma,
  lua = lua,
  rust = rust,
  c = c,
  cpp = c,
  go = function(text) return quoted(text, "`", true) or quoted(text, '"', false, "\\") end,
  json = function(text) return quoted(text, '"', false, "\\") end,
  jsonc = function(text) return quoted(text, '"', false, "\\") end,
  css = ordinary,
  scss = ordinary,
  php = php,
  php_only = php,
  bash = bash,
  sql = sql,
  html = function(text) return quoted(text, "'\"", true) end,
  xml = function(text) return quoted(text, "'\"", true) end,
}

-- Exempt executable/interpolated regions, but allow strings nested inside them.
local expressions = {
  interpolation = true,
  template_substitution = true,
  command_substitution = true,
  process_substitution = true,
  expansion = true,
  simple_expansion = true,
  variable_name = true,
}

local function in_expression(node, outer)
  while node and node ~= outer do
    if expressions[node:type()] then return true end
    node = node:parent()
  end
  return node == nil
end

function M.detect(info)
  local form_for = M.languages[info.language]
  if not form_for then return end
  local candidates, seen = {}, {}
  for _, capture in ipairs(info.captures()) do
    if capture.name == "string" or capture.name:match "^string%." then
      -- Some queries capture only the content; its parent owns the delimiters.
      for _, node in ipairs { capture.node, capture.node:parent() } do
        if not seen[node:id()] and info.contains(node) then
          seen[node:id()] = true
          candidates[#candidates + 1] = node
        end
      end
    end
  end
  table.sort(candidates, function(a, b) return a:byte_length() < b:byte_length() end)
  for _, node in ipairs(candidates) do
    if not node:has_error() and not in_expression(info.node, node) then
      local text = info.text(node)
      local form = form_for(text)
      if form and #text >= #form.opening + #form.closing and text:sub(-#form.closing) == form.closing then
        local _, _, start = node:start()
        local _, _, finish = node:end_()
        if info.offset >= start + #form.opening and info.offset <= finish - #form.closing then
          form.opening = nil
          return form
        end
      end
    end
  end
end

return M
