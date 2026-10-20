-- Run from the config root: nvim --headless -u NONE -i NONE -l tests/minuet_completion.lua
local root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(root)
local guard = require "util.minuet_completion"
local contexts = require "util.minuet_context"
local boundary = require "util.minuet_context.boundary"
local passed = 0

local function check(name, run)
  local ok, err = xpcall(run, debug.traceback)
  if not ok then error(name .. "\n" .. err) end
  passed = passed + 1
  print("PASS " .. name)
end

local function filter(text, after, incomplete)
  return guard.filter(text, { lines_after = after, opts = { is_incomplete_after = incomplete } })
end

local function string_context(quote, after)
  return {
    lines_after = after,
    scope = { filter = boundary.filter, state = { closing = quote, escape = "\\", multiline = false } },
  }
end

local branch = "    elif n == 1:\n        return 0"
local suffix = '"\n' .. branch .. "\n    elif n == 2:\n        return 1"

check("reuse existing inline space without removing indentation or internal spaces", function()
  assert(guard.filter(" not  valid", { lines_before = 'return "This is ' }) == "not  valid")
  assert(guard.filter("  not valid", { lines_before = 'return "This is ' }) == "not valid")
  assert(guard.filter(" not valid", { lines_before = 'return "This is' }) == " not valid")
  assert(guard.filter("    return 0", { lines_before = "if valid:\n    " }) == "    return 0")
  assert(guard.filter("\n    return 0", { lines_before = "if valid: " }) == "\n    return 0")
  assert(guard.filter("\tvalue", { lines_before = "return " }) == "\tvalue")
end)

check("rephrased branches cannot escape an ordinary string completion", function()
  local suggestion = ' not a valid input"\n    elif n not in [1, 2]:\n        return fibonacci(n - 1)\n    else:'
  assert(guard.filter(suggestion, string_context('"', suffix)) == " not a valid input")
  assert(guard.filter(" not a valid input\n    else:", string_context '"') == " not a valid input")
end)

check("string boundaries preserve escaped quotes, opposite quotes, and Unicode", function()
  local text = [[ say \"hello\" and 'سلام']]
  assert(guard.filter(text .. '"\nextra()', string_context '"') == text)
  assert(guard.filter([[ don't]], string_context '"') == [[ don't]])
  assert(guard.filter([[ it\'s valid'\nextra()]], string_context "'") == [[ it\'s valid]])
end)

check("string boundaries do not leave a dangling backslash or literal newline", function()
  assert(guard.filter("text\\", string_context '"') == "text")
  assert(guard.filter("text\\\nextra()", string_context '"') == "text")
  assert(guard.filter("text\r\nextra()", string_context '"') == "text")
  assert(guard.filter('"\nextra()', string_context '"') == nil)
  assert(guard.filter("\nextra()", string_context '"') == nil)
end)

check("screenshot: cut copied branches and remove the existing closing quote", function()
  local suggestion = ' is not a valid number"\n' .. branch .. "\n    else:\n        for i in range"
  assert(filter(suggestion, suffix) == " is not a valid number")
end)

check("preserve useful multiple lines before a duplicate", function()
  local prefix = "\n        log(n)\n        return n"
  assert(filter(prefix .. "\n" .. branch .. "\n    else:", "\n" .. branch) == prefix)
end)

check("entirely duplicated and whitespace-only suggestions disappear", function()
  assert(filter(branch, "\n" .. branch) == nil)
  assert(filter("\n\n" .. branch, "\n" .. branch) == nil)
  assert(filter(" \n\t", "") == nil)
end)

check("one common line is insufficient", function()
  local suggestion = "\n    elif n == 1:\n        return 100"
  assert(filter(suggestion, "\n" .. branch) == suggestion)
end)

check("match complete lines rather than substrings", function()
  local suggestion = "new " .. branch .. "\n" .. branch .. "0"
  assert(filter(suggestion, "\n" .. branch) == suggestion)
end)

check(
  "cut at the earliest of multiple copied blocks",
  function() assert(filter("new\n" .. branch .. "\nmore\n" .. branch .. "\nextra", "\n" .. branch) == "new") end
)

check("match indentation exactly", function()
  local suggestion = "new\nelif n == 1:\n    return 0\nextra"
  assert(filter(suggestion, "\n" .. branch) == suggestion)
end)

check("preserve leading newlines, tabs, trailing spaces, and Unicode", function()
  local suggestion = "\n\tپیام = 'سلام'  \n\treturn پیام\n\n"
  assert(filter(suggestion, "") == suggestion)
  assert(filter(suggestion, "\n" .. branch) == suggestion)
end)

check("keep intervening blank lines in the block match", function()
  local block = "    elif n == 1:\n\n        return 0"
  assert(filter("new\n" .. block .. "\nextra", "\n\n" .. block) == "new")
  local different = "new\n" .. branch .. "\nextra"
  assert(filter(different, "\n\n" .. block) == different)
end)

check("do not treat a truncated suffix line as a complete anchor", function()
  local suggestion = "new\n" .. branch .. "\nextra"
  assert(filter(suggestion, "\n" .. branch, true) == suggestion)
  assert(filter(suggestion, "\n" .. branch .. "\npartial", true) == "new")
end)

check("trim exact trailing overlap of at least 15 characters", function()
  local overlap = "existing_suffix_value"
  assert(filter("  new\n" .. overlap, overlap .. "\nrest") == "  new\n")
  assert(filter(overlap, overlap) == nil)
  assert(filter("newabcdefghijklmn", "abcdefghijklmn") == "newabcdefghijklmn")
  assert(filter("newabcdefghijklmno", "abcdefghijklmno") == "new")
end)

check("measure overlap threshold in characters, including Unicode", function()
  local short = "سلام"
  local long = string.rep("س", 15)
  assert(filter("new " .. short, short) == "new " .. short)
  assert(filter("new " .. long, long .. " rest") == "new ")
end)

check("only remove a short inline remainder after a confirmed block match", function()
  assert(filter('hello"', suffix) == 'hello"')
  assert(filter("hello\n" .. branch, suffix) == "hello")
end)

check("ignore non-immediate repeated blocks", function()
  local after = "\n    first()\n    second()\n" .. branch
  local suggestion = "new\n" .. branch .. "\nextra"
  assert(filter(suggestion, after) == suggestion)
end)

check("nil text, missing context, and empty suffix are safe", function()
  assert(guard.filter(nil, {}) == nil)
  assert(guard.filter "\n  new  " == "\n  new  ")
  assert(filter("\n  new  ", "") == "\n  new  ")
end)

check("provider wrapper is idempotent and snapshots each asynchronous request", function()
  local module = "minuet.backends.openai_fim_compatible"
  local saved = package.loaded[module]
  local requests = {}
  local provider = {
    complete = function(context, callback)
      requests[#requests + 1] = { context = context, callback = callback }
      return "job"
    end,
  }
  package.loaded[module] = provider
  local ok, err = pcall(function()
    guard.install()
    local wrapped = provider.complete
    guard.install()
    assert(provider.complete == wrapped)

    local context = { lines_before = "prefix ", lines_after = suffix, opts = { is_incomplete_after = false } }
    local result
    assert(provider.complete(context, function(items) result = items end) == "job")
    assert(requests[1].context == context)
    context.lines_before = "different prefix"
    context.lines_after = "different buffer"
    context.opts.is_incomplete_after = true
    local other
    provider.complete({ lines_after = "" }, function(items) other = items end)
    requests[2].callback { "\n  useful  " }
    vim.api.nvim_create_buf(false, true)
    requests[1].callback { ' new"\n' .. branch .. "\nextra", "\n" .. branch, "\n  useful  " }
    assert(vim.deep_equal(result, { "new", "\n  useful  " }))
    assert(vim.deep_equal(other, { "\n  useful  " }))
    requests[1].callback {}
    assert(vim.deep_equal(result, {}))
    requests[1].callback(nil)
    assert(result == nil)
  end)
  package.loaded[module] = saved
  assert(ok, err)
end)

local parser_ok, python_parser = pcall(vim.treesitter.language.add, "python")
if parser_ok and python_parser then
  check("snapshot Python string syntax without restricting code, docstrings, or f-string expressions", function()
    local module = "minuet.backends.openai_fim_compatible"
    local saved, previous_buffer = package.loaded[module], vim.api.nvim_get_current_buf()
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
    local pending
    package.loaded[module] = { complete = function(_, callback) pending = callback end }
    local ok, err = pcall(function()
      guard.install()
      local function complete(before, after, suggestion, expected)
        vim.bo.filetype = "python"
        vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(before .. after, "\n", { plain = true }))
        local lines = vim.split(before, "\n", { plain = true })
        vim.api.nvim_win_set_cursor(0, { #lines, #lines[#lines] })
        local result
        package.loaded[module].complete(
          { lines_before = before, lines_after = after },
          function(items) result = items end
        )
        -- Response filtering must use the syntax captured at request time.
        vim.bo.filetype = ""
        pending { suggestion }
        assert(vim.deep_equal(result, { expected }), vim.inspect { before, result, expected })
      end

      local branches = ' not a valid input"\n    elif n not in [1, 2]:\n        return fibonacci(n - 1)'
      complete('return "This is ', suffix, branches, "not a valid input")
      complete("return 'This is ", "'", "valid'\nextra()", "valid")
      complete('return r"This is ', '"', branches, "not a valid input")
      complete('return f"This is ', '"', branches, "not a valid input")
      local multiline = "text\n    more_text()"
      complete('return """This is ', '"""', multiline, multiline)
      complete('return """first\nThis is ', '\nlast"""', multiline, multiline)
      complete('return f"This is {', 'value}"', multiline, multiline)
      complete("result = call(", ")", multiline, multiline)
      complete('# "This is ', '"', multiline, multiline)
      complete('return "This is ', "", multiline, multiline)

      local get_parser = vim.treesitter.get_parser
      vim.treesitter.get_parser = function() error "parser unavailable" end
      local parsed, parse_err = pcall(complete, 'return "This is ', '"', multiline, multiline)
      vim.treesitter.get_parser = get_parser
      assert(parsed, parse_err)
    end)
    package.loaded[module] = saved
    vim.api.nvim_set_current_buf(previous_buffer)
    vim.api.nvim_buf_delete(buffer, { force = true })
    assert(ok, err)
  end)
else
  print "SKIP Python syntax integration: parser is not installed"
end

-- Use the installed Minuet UI in an embedded child, so input really enters
-- insert mode and scheduled acceptance follows the same path as an editor.
local plugin = vim.fn.stdpath "data" .. "/lazy/minuet-ai.nvim"
if vim.fn.isdirectory(plugin) == 1 then
  check("Minuet setup, ghost text, full acceptance, and line acceptance", function()
    local child = vim.fn.jobstart({ vim.v.progpath, "--embed", "--headless", "-u", "NONE", "-i", "NONE" }, {
      rpc = true,
      env = { NVIM_LOG_FILE = vim.fn.tempname() },
    })
    assert(child > 0)
    local function exec(code, args) return vim.rpcrequest(child, "nvim_exec_lua", code, args or {}) end
    local ok, err = pcall(function()
      exec(
        [[
        local root, plugin = ...
        vim.opt.runtimepath:prepend(root)
        vim.opt.runtimepath:prepend(plugin)
        vim.o.swapfile = false
        local spec = dofile(root .. '/lua/plugins/minuet.lua')[1]
        assert(spec.opts.context_window == 2048 and spec.opts.context_ratio == 0.65)
        assert(spec.opts.provider_options.openai_fim_compatible.optional.options.num_ctx == 2048)
        assert(spec.opts.before_cursor_filter_length == 0 and spec.opts.after_cursor_filter_length == 0)
        -- Configure before loading the real provider, which checks API settings.
        require('minuet').setup(spec.opts)
        _G.minuet_requests = 0
        require('minuet.backends.openai_fim_compatible').complete = function(context, callback)
          _G.minuet_requests = _G.minuet_requests + 1
          callback({ _G.minuet_mock })
        end
        spec.config(nil, spec.opts)
        _G.minuet_spec = spec
        for i = 1, 2 do
          vim.keymap.set('i', spec.keys[i][1], spec.keys[i][2])
        end
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
          'def fibonacci(n):', '    if n <= 0:', '        return "This is "',
          '    elif n == 1:', '        return 0', '    elif n == 2:', '        return 1',
        })
        vim.api.nvim_win_set_cursor(0, { 3, #('        return "This is ') })
        vim.bo.filetype = 'python'
        vim.b.minuet_virtual_text_auto_trigger = false
        _G.minuet_mock = ' not a valid number"\n    elif n not in [1, 2]:\n        return fibonacci(n - 1)\n    else:'
      ]],
        { root, plugin }
      )
      vim.rpcrequest(child, "nvim_input", "i")
      assert(vim.wait(1000, function() return exec "return vim.fn.mode()" == "i" end))
      exec "require('minuet.virtualtext').action.next()"
      assert(exec "return require('minuet.virtualtext').action.is_visible()")
      local marks =
        exec "return vim.api.nvim_buf_get_extmarks(0, require('minuet.virtualtext').ns_id, 0, -1, { details = true })"
      assert(marks[1][4].virt_text[1][1] == "not a valid number")
      assert(not marks[1][4].virt_lines or #marks[1][4].virt_lines == 0)

      -- Stop follow-up output while still counting the accept-and-continue request.
      exec "_G.minuet_mock = ''; _G.minuet_requests = 0"
      vim.rpcrequest(child, "nvim_input", "<A-l>")
      assert(vim.wait(1000, function() return exec "return _G.minuet_requests" > 0 end))
      local lines = exec "return vim.api.nvim_buf_get_lines(0, 0, -1, false)"
      assert(lines[3] == '        return "This is not a valid number"')
      assert(#lines == 7 and lines[4] == "    elif n == 1:")

      vim.rpcrequest(child, "nvim_input", "<Esc>")
      assert(vim.wait(1000, function() return exec "return vim.fn.mode()" == "n" end))
      exec [[
        require('minuet.virtualtext').action.dismiss()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'value = ' })
        vim.api.nvim_win_set_cursor(0, { 1, #('value = ') - 1 })
        _G.minuet_mock = 'first()\nsecond()\nthird()'
      ]]
      vim.rpcrequest(child, "nvim_input", "a")
      assert(vim.wait(1000, function() return exec "return vim.fn.mode()" == "i" end))
      exec "require('minuet.virtualtext').action.next(); _G.minuet_requests = 0"
      vim.rpcrequest(child, "nvim_input", "<A-k>")
      local accepted = vim.wait(
        1000,
        function() return exec "return vim.api.nvim_get_current_line()" == "value = first()" end
      )
      assert(accepted, vim.inspect(exec "return { vim.api.nvim_get_current_line(), vim.fn.mode() }"))
      -- Let the mapping's defer finish: it must retain the remaining lines.
      exec "vim.wait(30)"
      assert(exec "return _G.minuet_requests" == 0)
      assert(exec "return require('minuet.virtualtext').action.is_visible()")
      marks =
        exec "return vim.api.nvim_buf_get_extmarks(0, require('minuet.virtualtext').ns_id, 0, -1, { details = true })"
      assert(marks[1][4].virt_text[1][1] == "")
      assert(marks[1][4].virt_lines[1][1][1] == "second()")
    end)
    vim.fn.jobstop(child)
    assert(ok, err)
  end)
else
  print "SKIP Minuet UI integration: plugin is not installed"
end

print(("All %d Minuet completion checks passed"):format(passed))
