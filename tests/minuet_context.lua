-- Run from the config root: nvim --headless -n -u NONE -i NONE -l tests/minuet_context.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
local contexts = require "util.minuet_context"
local boundary = require "util.minuet_context.boundary"
local strings = require "util.minuet_context.strings"
local passed, skipped = 0, 0

local function check(name, run)
  local ok, err = xpcall(run, debug.traceback)
  assert(ok, name .. "\n" .. tostring(err))
  passed = passed + 1
  print("PASS " .. name)
end

local function at_cursor(language, before, after, run)
  local previous, virtualedit = vim.api.nvim_get_current_buf(), vim.wo.virtualedit
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buffer)
  vim.wo.virtualedit = "onemore"
  local ok, err = pcall(function()
    vim.bo.filetype = language
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(before .. after, "\n", { plain = true }))
    local lines = vim.split(before, "\n", { plain = true })
    vim.api.nvim_win_set_cursor(0, { #lines, #lines[#lines] })
    run { lines_before = before, lines_after = after }
  end)
  vim.api.nvim_set_current_buf(previous)
  vim.wo.virtualedit = virtualedit
  vim.api.nvim_buf_delete(buffer, { force = true })
  assert(ok, err)
end

local cases = {
  { "python", 'value = "hello ', '"', 'world"\nextra()', "world" },
  { "python", "value = 'hello ", "'", "world'\nextra()", "world" },
  { "python", 'value = "hello ', '"', [[say \"سلام\"";extra]], [[say \"سلام\"]] },
  { "python", 'value = r"hello ', '"', [[world\"still string";extra]], [[world\"still string]] },
  { "python", 'value = """hello ', '"""', 'world\nmore"""\nextra()', "world\nmore" },
  { "python", 'value = """first\nhello ', '\nlast"""', 'world\nmore"""\nextra()', "world\nmore" },
  { "python", 'value = f"hello {', 'value}"', "first()\nsecond()", "first()\nsecond()", false },
  { "python", "value = f\"hello {fn('inner ", "')}\"", "world'\nextra()", "world" },
  { "javascript", 'const x = "hello ', '";', 'world"; extra()', "world" },
  { "javascript", "const x = 'hello ", "';", "world'; extra()", "world" },
  { "javascript", "const x = `hello ", "`;", "world\nmore`; extra()", "world\nmore" },
  { "javascript", "const x = `hello ${", "value}`;", "first()\nsecond()", "first()\nsecond()", false },
  { "javascript", 'const x = `hello ${fn("inner ', '")}`;', 'world"; extra()', "world" },
  { "typescript", 'const x: string = "hello ', '";', 'world"; extra()', "world" },
  { "tsx", 'const x = <p title="hello ', '">text</p>;', 'world"; extra()', "world" },
  { "lua", 'local x = "hello ', '"', 'world"\nextra()', "world" },
  { "lua", "local x = [=[hello ", "]=]", 'world\nquotes" and ]] stay]=]\nextra()', 'world\nquotes" and ]] stay' },
  { "lua", "local x = [[first\nhello ", "\nlast]]", "world\nmore]]\nextra()", "world\nmore" },
  { "rust", 'fn main() { let x = "hello ', '"; }', 'world\nmore"; extra()', "world\nmore" },
  {
    "rust",
    'fn main() { let x = r##"hello ',
    '"##; }',
    'world" and \\raw\nmore"##; extra()',
    'world" and \\raw\nmore',
  },
  { "c", 'void f() { char *x = "hello ', '"; }', 'world"; extra()', "world" },
  { "c", 'void f() { wchar_t *x = L"hello ', '"; }', 'world"; extra()', "world" },
  { "cpp", 'auto x = R"tag(hello ', ')tag";', 'world\nmore)tag"; extra()', "world\nmore" },
  { "go", 'package main\nvar x = "hello ', '"', 'world"\nextra()', "world" },
  { "go", "package main\nvar x = `hello ", "`", "world\nmore`\nextra()", "world\nmore" },
  { "json", '{"key":"hello ', '"}', 'world"}, extra', "world" },
  { "css", 'a { content: "hello ', '"; }', 'world"; extra', "world" },
  { "scss", 'a { content: "hello ', '"; }', 'world"; extra', "world" },
  { "php", '<?php $x = "hello ', '";', 'world\nmore"; extra()', "world\nmore" },
  { "php", "<?php $x = 'hello ", "';", "world' ; extra()", "world" },
  { "php_only", '$x = "hello ', '";', 'world"; extra()', "world" },
  { "php", '<?php $x = "hello {$', 'name}";', "first()\nsecond()", "first()\nsecond()", false },
  { "bash", 'echo "hello ', '"', 'world"; extra', "world" },
  { "bash", "echo 'hello ", "'", "world\\' ; extra", "world\\" },
  { "bash", 'echo "hello ${', 'name}"', "first()\nsecond()", "first()\nsecond()", false },
  { "bash", 'echo "hello $(', 'pwd)"', "first()\nsecond()", "first()\nsecond()", false },
  { "sql", "SELECT 'hello ", "';", "world''s'; extra", "world''s" },
  { "html", '<p title="hello ', '">text</p>', 'world" other=bad>', "world" },
  { "html", '<p title="hello ', '">text</p>', [[world\" other=bad>]], [[world\]] },
  { "html", '<script>const x = "hello ', '";</script>', 'world"; extra()', "world" },
  { "html", "<p>hel", "lo</p>", "world</p><script>extra()</script>", "world</p><script>extra()</script>", false },
  { "python", '# "hello ', '"', 'world"\nextra()', 'world"\nextra()', false },
  { "python", 'value = "hello ', "", 'world"\nextra()', 'world"\nextra()', false },
  { "javascript", "const x = call(", ");", "first()\nsecond()", "first()\nsecond()", false },
}

for i, case in ipairs(cases) do
  local language, before, after, text, expected, scoped = unpack(case)
  local ok, loaded = pcall(vim.treesitter.language.add, language)
  if ok and loaded then
    check(("%s context %d"):format(language, i), function()
      at_cursor(language, before, after, function(request)
        local scope = contexts.capture(request)
        if scoped == false then
          assert(scope == nil, "unexpected scope: " .. vim.inspect(scope))
        else
          assert(scope and scope.name == "string", "expected string scope")
        end
        assert(contexts.filter(text, scope) == expected, vim.inspect { text, expected, scope })
      end)
    end)
  else
    skipped = skipped + 1
    print("SKIP " .. language .. ": parser not installed")
  end
end

check("language form adapters handle raw and doubled delimiters", function()
  for _, case in ipairs {
    { "cpp", 'u8R"tag(hello )tag"', 'world\nmore)tag"; extra', "world\nmore" },
    { "go", "`hello `", "world\nmore`\nextra", "world\nmore" },
    { "json", '"hello "', 'world"}, extra', "world" },
    { "sql", "E'hello '", [[it\'s''valid';extra]], [[it\'s''valid]] },
  } do
    local form = assert(strings.languages[case[1]](case[2]))
    assert(boundary.filter(case[3], form) == case[4])
  end
end)

check("partial delimiters cannot close a literal across the insertion boundary", function()
  assert(boundary.filter('world""', { closing = '"""', multiline = true }) == "world")
  assert(boundary.filter("world]=", { closing = "]=]", multiline = true }) == "world")
  assert(boundary.filter('world"', { closing = '"##', multiline = true }) == 'world"')
end)

check("missing queries, unknown forms, and mismatched requests leave completions alone", function()
  at_cursor("python", 'x = "hello ', '"', function(request)
    local get_query = vim.treesitter.query.get
    vim.treesitter.query.get = function() return nil end
    local ok, scope = pcall(contexts.capture, request)
    vim.treesitter.query.get = get_query
    assert(ok and scope == nil)
    local python = strings.languages.python
    strings.languages.python = nil
    scope = contexts.capture(request)
    strings.languages.python = python
    assert(scope == nil)
    assert(contexts.capture { lines_before = "different", lines_after = request.lines_after } == nil)
  end)
  assert(contexts.filter("text", { filter = function() error "broken extension" end }) == "text")
  assert(contexts.filter("text", { filter = function() return nil end }) == "")
end)

check("register an HTML-text rule without changing the string rule or provider", function()
  local state = { closing = "<", multiline = true }
  contexts.register { name = "broken", detect = function() error "broken detector" end, filter = boundary.filter }
  contexts.register {
    name = "example_html_text",
    detect = function(info)
      if info.language == "html" and info.node:type() == "text" then return state end
    end,
    filter = boundary.filter,
  }
  local ok, err = pcall(function()
    at_cursor("html", "<p>hel", "lo</p>", function(request)
      local scope = assert(contexts.capture(request))
      assert(scope.name == "example_html_text")
      state.closing = "changed after request"
      -- Updating a rule must not change already pending requests.
      contexts.register { name = "example_html_text", detect = function() end, filter = function() return "changed" end }
      assert(contexts.filter("world\nmore</p><script>extra()</script>", scope) == "world\nmore")
      assert(contexts.capture(request) == nil)
    end)
  end)
  contexts.unregister "example_html_text"
  contexts.unregister "broken"
  assert(ok, err)
end)

print(("All %d context checks passed (%d skipped: missing parsers)"):format(passed, skipped))
