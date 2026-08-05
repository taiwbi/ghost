local FILE_BG = "#DA627D"
local MODE_FG = "#1a1b26"

local icons = require "util.icons"

local function current_mode()
  return icons.modes[vim.fn.mode()] or { name = vim.fn.mode():upper(), color = "#7AA2F7" }
end

local function has_filename() return vim.fn.expand "%:t" ~= "" end

local function pending_keys()
  local which_key = package.loaded["which-key.state"]
  local state = which_key and which_key.state
  local keys = state and state.node and state.node.keys or ""
  return keys ~= "" and (" " .. keys .. " ") or ""
end

local function get_hl(group, attr)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  if attr == "fg" then return hl.fg and string.format("#%06x", hl.fg) or nil end
  if attr == "bg" then return hl.bg and string.format("#%06x", hl.bg) or nil end
  return hl
end

local mode_block = {
  init = function(self) self.mode = current_mode() end,
  {
    provider = "",
    hl = function(self) return { fg = self.mode.color, bg = "NONE" } end,
  },
  {
    provider = function(self) return " " .. icons.ui.VimIcon .. " " .. self.mode.name .. " " end,
    hl = function(self) return { fg = MODE_FG, bg = self.mode.color, bold = true } end,
  },
}

local mode_to_file_sep = {
  init = function(self) self.mode = current_mode() end,
  provider = "",
  hl = function(self)
    return {
      fg = self.mode.color,
      bg = has_filename() and FILE_BG or "NONE",
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
    provider = "",
    hl = function() return { fg = FILE_BG, bg = "NONE" } end,
  },
}

local cmd_info = {
  {
    condition = function() return vim.fn.reg_recording() ~= "" end,
    provider = function() return " recording @" .. vim.fn.reg_recording() .. " " end,
    hl = { fg = "#E0AF68" },
  },
  {
    condition = function() return vim.v.hlsearch == 1 and vim.fn.searchcount({ maxcount = 999, timeout = 250 }).total > 0 end,
    provider = function()
      local s = vim.fn.searchcount { maxcount = 999, timeout = 250 }
      if s.total > 0 then return string.format(" %d/%d ", s.current, s.total) end
      return ""
    end,
    hl = { fg = "#9ECE6A" },
  },
  {
    provider = pending_keys,
  },
}

local breadcrumbs = {
  condition = function()
    local ok = pcall(require, "nvim-navic")
    return ok and require("nvim-navic").is_available()
  end,
  init = function(self)
    self.data = require("nvim-navic").get_data() or {}
  end,
  provider = function(self)
    local parts = {}
    for _, item in ipairs(self.data) do
      table.insert(parts, item.name)
    end
    if #parts == 0 then return "" end
    return "  " .. table.concat(parts, "  ")
  end,
  update = "CursorMoved",
}

local function lsp_breadcrumbs()
  local ok, _ = pcall(require, "nvim-navic")
  if ok then return breadcrumbs end
  return {
    provider = function()
      local node = vim.treesitter.get_node()
      if not node then return "" end
      local parts = {}
      while node do
        local t = node:type()
        if t:match "function" or t:match "method" or t:match "class" then
          local row, col = node:start()
          local name_node = node:field("name")[1] or node:field("declarator")[1]
          if name_node then
            local txt = vim.treesitter.get_node_text(name_node, 0)
            if txt then table.insert(parts, 1, txt) end
          end
        end
        node = node:parent()
      end
      if #parts == 0 then return "" end
      return "  " .. table.concat(parts, "  ")
    end,
    update = { "CursorMoved", "CursorHold" },
  }
end

local git_diff = {
  condition = function() return vim.b.gitsigns_status_dict ~= nil end,
  init = function(self) self.status = vim.b.gitsigns_status_dict or {} end,
  {
    provider = function(self)
      local n = self.status.added or 0
      return n > 0 and ("  " .. n) or ""
    end,
    hl = { fg = "#9ECE6A" },
  },
  {
    provider = function(self)
      local n = self.status.changed or 0
      return n > 0 and ("  " .. n) or ""
    end,
    hl = { fg = "#E0AF68" },
  },
  {
    provider = function(self)
      local n = self.status.removed or 0
      return n > 0 and ("  " .. n) or ""
    end,
    hl = { fg = "#F7768E" },
  },
}

local function diag_count(severity) return #vim.diagnostic.get(0, { severity = severity }) end

local diagnostics = {
  condition = function() return #vim.diagnostic.get(0) > 0 end,
  update = { "DiagnosticChanged", "BufEnter" },
  {
    provider = function()
      local n = diag_count(vim.diagnostic.severity.ERROR)
      return n > 0 and ("  " .. icons.diagnostics.Error .. n) or ""
    end,
    hl = { fg = "#F7768E" },
  },
  {
    provider = function()
      local n = diag_count(vim.diagnostic.severity.WARN)
      return n > 0 and ("  " .. icons.diagnostics.Warn .. n) or ""
    end,
    hl = { fg = "#E0AF68" },
  },
  {
    provider = function()
      local n = diag_count(vim.diagnostic.severity.INFO)
      return n > 0 and ("  " .. icons.diagnostics.Info .. n) or ""
    end,
    hl = { fg = "#7DCFFF" },
  },
  {
    provider = function()
      local n = diag_count(vim.diagnostic.severity.HINT)
      return n > 0 and ("  " .. icons.diagnostics.Hint .. n) or ""
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
    return string.format("  %d:%d  %d%% ", cur, col, pct)
  end,
}

local mode_right = {
  init = function(self) self.mode = current_mode() end,
  {
    provider = " ",
    hl = function(self) return { fg = self.mode.color, bg = "NONE" } end,
  },
  {
    provider = "",
    hl = function(self) return { fg = self.mode.color, bg = "NONE" } end,
  },
  {
    provider = function(self) return " " .. self.mode.name .. " " end,
    hl = function(self) return { fg = MODE_FG, bg = self.mode.color, bold = true } end,
  },
}

local fill = { provider = "%=" }

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
        cmd_info,
        fill,
        lsp_breadcrumbs(),
        fill,
        git_diff,
        diagnostics,
        nav,
        mode_right,
      },
    }
  end,
  config = function(_, opts)
    require("heirline").setup(opts)
    vim.api.nvim_create_autocmd("ModeChanged", {
      group = vim.api.nvim_create_augroup("heirline_mode_redraw", { clear = true }),
      callback = function() vim.cmd.redrawstatus() end,
    })
  end,
  specs = {
    {
      "SmiteshP/nvim-navic",
      lazy = true,
      opts = {
        icons = setmetatable({}, { __index = function() return "" end }),
        highlight = false,
        separator = "  ",
        depth_limit = 0,
        click = false,
      },
      init = function()
        vim.g.navic_silence = true
        vim.api.nvim_create_autocmd("LspAttach", {
          group = vim.api.nvim_create_augroup("user_navic_attach", { clear = true }),
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client.server_capabilities.documentSymbolProvider then
              require("nvim-navic").attach(client, args.buf)
            end
          end,
        })
      end,
    },
  },
}
