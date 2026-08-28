local FILE_BG = "#DA627D"
local MODE_FG = "#1a1b26"

local icons = require "util.icons"

local function current_mode() return icons.modes[vim.fn.mode()] or { name = vim.fn.mode():upper(), color = "#7AA2F7" } end

local function has_filename() return vim.fn.expand "%:t" ~= "" end

local breadcrumb_icons = setmetatable({
  File = "󰈙 ",
  Module = "󰏗 ",
  Namespace = "󰦮 ",
  Package = "󰏗 ",
  Class = "󰠱 ",
  Method = "󰆧 ",
  Property = "󰜢 ",
  Field = "󰜢 ",
  Constructor = " ",
  Enum = " ",
  Interface = " ",
  Function = "󰊕 ",
  Variable = "󰀫 ",
  Constant = "󰏿 ",
  String = "󰀬 ",
  Number = "󰎠 ",
  Boolean = "◩ ",
  Array = "󰅪 ",
  Object = "󰅩 ",
  Key = "󰌋 ",
  Null = "󰟢 ",
  EnumMember = " ",
  Struct = "󰙅 ",
  Event = " ",
  Operator = "󰆕 ",
  TypeParameter = "󰊄 ",
  Element = "󰓫 ",
  Directive = "󰘧 ",
}, { __index = function() return "" end })

local html_tag_icons = setmetatable({
  html = "󰗀 ",
  head = "󰒮 ",
  body = "󰦪 ",
  title = "󰗀 ",
  meta = "󰍽 ",
  link = "󰌷 ",
  script = "󰌨 ",
  style = "󰟾 ",
  main = "󰧮 ",
  section = "󰙅 ",
  article = "󰗀 ",
  header = "󰶐 ",
  footer = "󰋚 ",
  nav = "󰛐 ",
  aside = "󰣇 ",
  div = "󰉋 ",
  span = "󰉋 ",
  p = "󰍔 ",
  a = "󰌷 ",
  button = "󰜄 ",
  form = "󰟵 ",
  input = "󰌆 ",
  label = "󰗧 ",
  img = "󰋩 ",
  ul = "󰮗 ",
  ol = "󰮗 ",
  li = "󰍴 ",
  table = "󰓫 ",
  tr = "󰓫 ",
  td = "󰓫 ",
}, { __index = function(_, name) return name:match "^x%-" and "󰘧 " or breadcrumb_icons.Element end })

local function html_tag_icon(name) return html_tag_icons[name:lower()] end

local function pending_keys()
  -- which-key keeps leader mappings in a human-readable form (`<Space>`),
  -- whereas Neovim's native showcmd renders Space as the raw `<20>` keycode.
  local which_key = package.loaded["which-key.state"]
  local state = which_key and which_key.state
  local keys = state and state.node and state.node.keys or ""
  if keys ~= "" then return " " .. keys .. " " end

  -- `%S` covers non-mapping input, including counts and the `q` macro prefix.
  return " %S "
end

local function get_hl(group, attr)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  if attr == "fg" then return hl.fg and string.format("#%06x", hl.fg) or nil end
  if attr == "bg" then return hl.bg and string.format("#%06x", hl.bg) or nil end
  return hl
end

local function statusline_bg() return get_hl("StatusLine", "bg") or "NONE" end

local mode_block = {
  init = function(self) self.mode = current_mode() end,
  {
    provider = function(self) return icons.ui.VimIcon .. " " .. self.mode.name .. " " end,
    hl = function(self) return { fg = MODE_FG, bg = self.mode.color, bold = true } end,
  },
}

local mode_to_file_sep = {
  init = function(self) self.mode = current_mode() end,
  provider = "",
  hl = function(self)
    return {
      fg = self.mode.color,
      bg = has_filename() and FILE_BG or statusline_bg(),
    }
  end,
}

local file_info = {
  condition = has_filename,
  {
    provider = function()
      local name = vim.fn.expand "%:t"
      return " " .. name .. (vim.bo.modified and " " or "") .. (vim.bo.modifiable == false and "  " or "") .. " "
    end,
    hl = { fg = MODE_FG, bg = FILE_BG, bold = true },
  },
  {
    provider = "",
    hl = function() return { fg = FILE_BG, bg = statusline_bg() } end,
  },
}

local git_branch = {
  condition = function()
    return has_filename() and vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.head ~= nil
  end,
  provider = function() return "  " .. vim.b.gitsigns_status_dict.head end,
  hl = { fg = "#7AA2F7" },
}

local function safe_searchcount()
  local ok, result = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 250 })
  return ok and result or nil
end

local cmd_info = {
  {
    condition = function() return vim.fn.reg_recording() ~= "" end,
    provider = function() return " recording @" .. vim.fn.reg_recording() .. " " end,
    hl = { fg = "#E0AF68" },
  },
  {
    condition = function()
      if vim.v.hlsearch ~= 1 then return false end
      local search = safe_searchcount()
      return search ~= nil and (search.total or 0) > 0
    end,
    provider = function()
      local s = safe_searchcount()
      if not s then return "" end
      if (s.total or 0) > 0 then return string.format(" %d/%d ", s.current or 0, s.total) end
      return ""
    end,
    hl = { fg = "#9ECE6A" },
  },
  {
    provider = pending_keys,
  },
}

local function treesitter_breadcrumbs()
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then
    local parser_ok, parser = pcall(vim.treesitter.get_parser, 0)
    if not parser_ok or not parser then return "" end

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local parse_ok, trees = pcall(parser.parse, parser)
    local tree = parse_ok and trees and trees[1]
    node = tree and tree:root():named_descendant_for_range(row - 1, col, row - 1, col)
    if not node then return "" end
  end

  local function child_of_type(parent, wanted)
    for child in parent:iter_children() do
      if child:type() == wanted then return child end
    end
  end

  local parts = {}
  while node do
    local t = node:type()
    if t == "element" then
      local start_tag = child_of_type(node, "start_tag") or child_of_type(node, "self_closing_tag")
      local tag_name = start_tag and child_of_type(start_tag, "tag_name")
      if tag_name then
        local name = vim.treesitter.get_node_text(tag_name, 0)
        table.insert(parts, 1, html_tag_icon(name) .. name)
      end
    elseif t == "directive" or t == "directive_start" then
      local name = vim.treesitter.get_node_text(node, 0):match "@([%w_]+)"
      if name then table.insert(parts, 1, breadcrumb_icons.Directive .. name) end
    elseif t == "section" or t:match "conditional" or t:match "loop" then
      for child in node:iter_children() do
        if child:type() == "directive_start" then
          local name = vim.treesitter.get_node_text(child, 0):match "@([%w_]+)"
          if name then table.insert(parts, 1, breadcrumb_icons.Directive .. name) end
          break
        end
      end
    elseif t:match "function" or t:match "method" or t:match "class" then
      local name_node = node:field("name")[1] or node:field("declarator")[1]
      if name_node then
        local txt = vim.treesitter.get_node_text(name_node, 0)
        if txt then
          local kind = t:match "class" and "Class" or t:match "method" and "Method" or "Function"
          table.insert(parts, 1, breadcrumb_icons[kind] .. txt)
        end
      end
    end
    node = node:parent()
  end

  if #parts == 0 then return "" end
  return "  " .. table.concat(parts, "  ")
end

local breadcrumbs = {
  condition = function() return vim.bo.buftype == "" end,
  init = function(self)
    local ok, navic = pcall(require, "nvim-navic")
    self.navic = ok and navic.is_available() and navic or nil
    self.data = self.navic and (self.navic.get_data() or {}) or {}
  end,
  provider = function(self)
    if not self.navic or #self.data == 0 then return treesitter_breadcrumbs() end
    return "  " .. self.navic.get_location()
  end,
  update = { "CursorMoved", "CursorMovedI", "CursorHold", "BufEnter", "LspAttach", "LspDetach" },
}

local function lsp_breadcrumbs() return breadcrumbs end

local git_diff = {
  condition = function() return vim.b.gitsigns_status_dict ~= nil end,
  init = function(self) self.status = vim.b.gitsigns_status_dict or {} end,
  {
    provider = function(self)
      local n = self.status.added or 0
      return n > 0 and ("  +" .. n) or ""
    end,
    hl = { fg = "#9ECE6A" },
  },
  {
    provider = function(self)
      local n = self.status.removed or 0
      return n > 0 and ("  -" .. n) or ""
    end,
    hl = { fg = "#F7768E" },
  },
}

local function diag_count(severity) return #vim.diagnostic.get(0, { severity = severity }) end

local errors = {
  condition = function() return diag_count(vim.diagnostic.severity.ERROR) > 0 end,
  update = { "DiagnosticChanged", "BufEnter" },
  {
    provider = function()
      local n = diag_count(vim.diagnostic.severity.ERROR)
      return n > 0 and ("   " .. n) or ""
    end,
    hl = { fg = "#F7768E" },
  },
}

local warnings = {
  condition = function() return diag_count(vim.diagnostic.severity.WARN) > 0 end,
  update = { "DiagnosticChanged", "BufEnter" },
  {
    provider = function()
      local n = diag_count(vim.diagnostic.severity.WARN)
      return n > 0 and ("   " .. n) or ""
    end,
    hl = { fg = "#E0AF68" },
  },
}

local info = {
  condition = function() return diag_count(vim.diagnostic.severity.INFO) > 0 end,
  update = { "DiagnosticChanged", "BufEnter" },
  {
    provider = function()
      local n = diag_count(vim.diagnostic.severity.INFO)
      return n > 0 and ("   " .. n) or ""
    end,
    hl = { fg = "#7DCFFF" },
  },
}

local hints = {
  condition = function() return diag_count(vim.diagnostic.severity.HINT) > 0 end,
  update = { "DiagnosticChanged", "BufEnter" },
  {
    provider = function()
      local n = diag_count(vim.diagnostic.severity.HINT)
      return n > 0 and ("  󰌵 " .. n) or ""
    end,
    hl = { fg = "#9ECE6A" },
  },
}

local nav = {
  provider = function()
    local cur = vim.fn.line "."
    local total = vim.fn.line "$"
    local col = vim.fn.virtcol "."
    local pct = math.floor((cur / total) * 100 + 0.5)
    return string.format("  %d:%d  %d%%%%", cur, col, pct)
  end,
}

local fill = { provider = "%=" }
local right_padding = { provider = "  " }

return {
  "rebelot/heirline.nvim",
  event = "UIEnter",
  dependencies = { "SmiteshP/nvim-navic" },
  opts = function()
    return {
      statusline = {
        hl = function() return { fg = get_hl("Normal", "fg") or "fg", bg = get_hl("StatusLine", "bg") or "bg" } end,
        mode_block,
        mode_to_file_sep,
        file_info,
        git_branch,
        git_diff,
        fill,
        cmd_info,
        errors,
        warnings,
        info,
        hints,
        nav,
        right_padding,
      },
      winbar = {
        hl = function()
          return {
            fg = get_hl("WinBar", "fg") or get_hl("Normal", "fg") or "fg",
            bg = get_hl("WinBar", "bg") or get_hl("Normal", "bg") or "bg",
          }
        end,
        lsp_breadcrumbs(),
      },
    }
  end,
  config = function(_, opts)
    require("heirline").setup(opts)

    local redraw_group = vim.api.nvim_create_augroup("heirline_redraw", { clear = true })

    vim.api.nvim_create_autocmd("ModeChanged", {
      group = redraw_group,
      callback = function() vim.cmd.redrawstatus() end,
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "LspAttach", "LspDetach" }, {
      group = redraw_group,
      callback = function(args)
        vim.schedule(function() vim.cmd.redrawstatus() end)
        if args.event == "LspAttach" then
          for _, delay in ipairs { 100, 500 } do
            vim.defer_fn(function() vim.cmd.redrawstatus() end, delay)
          end
        end
      end,
    })

    vim.api.nvim_create_autocmd("ColorScheme", {
      group = redraw_group,
      desc = "Rebuild Heirline highlights after a colorscheme change",
      callback = function()
        require("heirline.utils").on_colorscheme()
        vim.cmd.redrawstatus()
      end,
    })
  end,
  specs = {
    {
      "SmiteshP/nvim-navic",
      lazy = true,
      opts = {
        icons = breadcrumb_icons,
        separator = "  ",
        depth_limit = 0,
        click = true,
        highlight = true,
      },
      init = function()
        vim.g.navic_silence = true
        local function attach_navic(bufnr, client)
          local navic = require "nvim-navic"
          local clients = client and { client } or vim.lsp.get_clients { bufnr = bufnr }
          for _, lsp_client in ipairs(clients) do
            if lsp_client and lsp_client.server_capabilities.documentSymbolProvider then
              navic.attach(lsp_client, bufnr)
              return
            end
          end
        end

        vim.api.nvim_create_autocmd("LspAttach", {
          group = vim.api.nvim_create_augroup("user_navic_attach", { clear = true }),
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            attach_navic(args.buf, client)
          end,
        })

        vim.api.nvim_create_autocmd("BufEnter", {
          group = vim.api.nvim_create_augroup("user_navic_bufenter", { clear = true }),
          callback = function(args) attach_navic(args.buf) end,
        })

        attach_navic(vim.api.nvim_get_current_buf())
      end,
    },
  },
}
