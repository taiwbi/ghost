local augroup = function(name) return vim.api.nvim_create_augroup("user_" .. name, { clear = true }) end
local au = vim.api.nvim_create_autocmd

local buffer = require "util.buffer"

au({ "BufAdd", "BufEnter", "TabNewEntered" }, {
  group = augroup "bufferline_add",
  desc = "Maintain vim.t.bufs",
  callback = function(args)
    if not vim.t.bufs then vim.t.bufs = {} end
    if not buffer.is_valid(args.buf) then return end
    local bufs = vim.t.bufs
    if not vim.tbl_contains(bufs, args.buf) then
      table.insert(bufs, args.buf)
      vim.t.bufs = bufs
    end
    vim.t.bufs = vim.tbl_filter(buffer.is_valid, vim.t.bufs)
  end,
})

au({ "BufDelete", "TermClose" }, {
  group = augroup "bufferline_remove",
  desc = "Drop closed buffers from vim.t.bufs",
  callback = function(args)
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      local bufs = vim.t[tab].bufs
      if bufs then
        for i, bufnr in ipairs(bufs) do
          if bufnr == args.buf then
            table.remove(bufs, i)
            vim.t[tab].bufs = bufs
            break
          end
        end
      end
    end
    vim.t.bufs = vim.tbl_filter(buffer.is_valid, vim.t.bufs or {})
    vim.cmd.redrawtabline()
  end,
})

au({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup "checktime",
  desc = "Reload buffers changed outside Neovim",
  callback = function()
    if vim.bo.buftype ~= "nofile" then vim.cmd "checktime" end
  end,
})

au("BufWritePre", {
  group = augroup "create_dir",
  desc = "Auto-create parent directories on save",
  callback = function(args)
    local file = args.match
    if not buffer.is_valid(args.buf) or file:match "^%w+:[\\/][\\/]" then return end
    vim.fn.mkdir(vim.fn.fnamemodify(vim.uv.fs_realpath(file) or file, ":p:h"), "p")
  end,
})

au("TextYankPost", {
  group = augroup "highlight_yank",
  desc = "Briefly highlight yanked text",
  callback = function() (vim.hl or vim.highlight).on_yank() end,
})

au("BufReadPost", {
  group = augroup "restore_cursor",
  desc = "Restore cursor on file open",
  callback = function(args)
    if vim.b[args.buf].last_loc_restored or vim.bo[args.buf].filetype == "gitcommit" then return end
    vim.b[args.buf].last_loc_restored = true
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

au("BufWinEnter", {
  group = augroup "q_close",
  desc = "Bind q to :close in help/quickfix/scratch buffers",
  callback = function(args)
    if not vim.g.q_close_windows then vim.g.q_close_windows = {} end
    if vim.g.q_close_windows[args.buf] then return end
    vim.g.q_close_windows[args.buf] = true
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(args.buf, "n")) do
      if map.lhs == "q" then return end
    end
    if vim.tbl_contains({ "help", "nofile", "quickfix" }, vim.bo[args.buf].buftype) then
      vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = args.buf, silent = true, nowait = true })
    end
  end,
})

au("FileType", {
  group = augroup "unlist_qf",
  desc = "Unlist quickfix buffers",
  pattern = "qf",
  callback = function() vim.opt_local.buflisted = false end,
})

vim.api.nvim_create_user_command("WrapCssClasses", function()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local new_lines = {}

  for _, line in ipairs(lines) do
    if line:match 'class=".-"' then
      local indent = line:match "^%s*"
      local class_start = line:find 'class="'
      if class_start then
        local class_prefix = line:sub(1, class_start + 6)
        local class_content_start = class_start + 7
        local class_content_end = line:find('"', class_content_start)
        if class_content_end then
          local class_content = line:sub(class_content_start, class_content_end - 1)
          local suffix = line:sub(class_content_end)

          local classes = {}
          for c in class_content:gmatch "%S+" do
            table.insert(classes, c)
          end

          local current_line = class_prefix
          local continuation_indent = indent .. "    "
          local max_length = 120

          for _, class in ipairs(classes) do
            local first = current_line == class_prefix or current_line == continuation_indent
            local space_needed = first and 0 or 1
            if #current_line + space_needed + #class > max_length then
              table.insert(new_lines, current_line)
              current_line = continuation_indent .. class
            else
              if not first then current_line = current_line .. " " end
              current_line = current_line .. class
            end
          end
          table.insert(new_lines, current_line .. suffix)
        else
          table.insert(new_lines, line)
        end
      else
        table.insert(new_lines, line)
      end
    else
      table.insert(new_lines, line)
    end
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
  vim.api.nvim_win_set_cursor(0, cursor_pos)
end, {})

au("BufWritePost", {
  group = augroup "wrap_css_classes",
  desc = "Re-wrap long class attributes after formatting",
  pattern = { "*.html", "*.php", "*.blade.php" },
  callback = function()
    vim.defer_fn(function()
      vim.cmd "WrapCssClasses"
      vim.cmd "silent! noa write"
    end, 10)
  end,
})

vim.api.nvim_create_user_command("TransparentizeNeovide", function()
  if not vim.g.neovide then return end
  vim.g.neovide_opacity = 0.8
  local bg = "#191a22"
  for _, group in ipairs { "Normal", "NormalNC", "StatusLine", "VertSplit", "WinSeparator" } do
    vim.api.nvim_set_hl(0, group, { bg = bg, fg = group:match "Split" and bg or nil })
  end
end, {})

vim.api.nvim_create_user_command("ClearNeovideTransparency", function()
  if not vim.g.neovide then return end
  vim.g.neovide_opacity = 1
  local bg = "#1f212b"
  for _, group in ipairs { "Normal", "NormalNC", "StatusLine", "VertSplit", "WinSeparator" } do
    vim.api.nvim_set_hl(0, group, { bg = bg, fg = group:match "Split" and bg or nil })
  end
end, {})

local italic_groups = {
  "@comment",
  "@keyword",
  "@keyword.function",
  "@keyword.operator",
  "@keyword.return",
  "@keyword.conditional",
  "@keyword.repeat",
  "@storageclass",
  "@type.builtin",
  "@constant.builtin",
  "@variable.builtin",
  "Keyword",
  "StorageClass",
  "Constant",
  "Comment",
}

local function apply_italics()
  for _, group in ipairs(italic_groups) do
    local hl = vim.api.nvim_get_hl(0, { name = group })
    if hl and not vim.tbl_isempty(hl) then
      hl.italic = true
      vim.api.nvim_set_hl(0, group, hl)
    end
  end
end

au("ColorScheme", {
  group = augroup "italics",
  desc = "Re-apply italic emphasis after every colorscheme load",
  callback = function() vim.defer_fn(apply_italics, 50) end,
})

vim.g.theme_sync = {
  dark = { colorscheme = "vague" },
  light = { colorscheme = "onedark" },
  highlights = {
    vague = {
      dark = {
        SnacksPicker = { bg = "#141415" },
        SnacksPickerBorder = { bg = "#141415" },
        SnacksPickerSearch = { bg = "#141415" },
        SnacksPickerTitle = { bg = "#141415" },
        SnacksInputTitle = { bg = "#141415" },
        FloatTitle = { bg = "#141415" },
        WhichKeyNormal = { bg = "#141415" },
        WhichKeyBorder = { bg = "#141415" },
        WhichKeyTitle = { bg = "#141415" },
      },
    },
    nordic = {
      dark = {
        WhichKeyBorder = { bg = "#242933", fg = "#191d24" },
      },
    },
    gruvbox = {
      dark = {
        SignColumn = { bg = "#282828" },
        FoldColumn = { bg = "#282828" },
      },
      light = {
        SignColumn = { bg = "#F9F5D7" },
        FoldColumn = { bg = "#F9F5D7" },
      },
    },
    kanagawa = {
      dark = {
        NoicePopupBorder = { bg = "#181616", fg = "#54546D" },
        NoiceCmdlinePopupBorder = { bg = "#181616", fg = "#54546D" },
        NoiceCmdlinePopupBorderCmdline = { bg = "#181616", fg = "#54546D" },
        NoiceCmdLineIcon = { bg = "#181616", fg = "#54546D" },
        NoiceCmdlineIconSearch = { bg = "#181616", fg = "#54546D" },
        NoiceCmdlinePopupBorderSearch = { bg = "#181616", fg = "#54546D" },
        NoiceConfirmBorder = { bg = "#181616", fg = "#54546D" },
        NoicePopupmenuBorder = { bg = "#181616", fg = "#54546D" },
        NoiceSplitBorder = { bg = "#181616", fg = "#54546D" },
        FloatBorder = { bg = "#181616", fg = "#54546D" },
        VertSplit = { bg = "#181616", fg = "#54546D" },
        WinSeparator = { bg = "#181616", fg = "#54546D" },
        NeoTreeWinSeparator = { bg = "#181616", fg = "#54546D" },
        LineNr = { bg = "#181616" },
        FoldColumn = { bg = "#181616" },
        SignColumn = { bg = "#181616" },
        GitSigns = { bg = "#181616" },
        GitSignsAdd = { bg = "#181616", fg = "#76946a" },
        GitSignsDelete = { bg = "#181616", fg = "#c34043" },
        GitSignsChange = { bg = "#181616", fg = "#dca561" },
      },
      light = {
        NoicePopupBorder = { bg = "#F2ECBC", fg = "#D5CEAC" },
        NoiceCmdlinePopupBorder = { bg = "#F2ECBC", fg = "#D5CEAC" },
        NoiceCmdlinePopupBorderCmdline = { bg = "#F2ECBC", fg = "#D5CEAC" },
        NoiceCmdLineIcon = { bg = "#F2ECBC", fg = "#D5CEAC" },
        NoiceCmdlineIconSearch = { bg = "#F2ECBC", fg = "#D5CEAC" },
        NoiceCmdlinePopupBorderSearch = { bg = "#F2ECBC", fg = "#D5CEAC" },
        NoiceConfirmBorder = { bg = "#F2ECBC", fg = "#D5CEAC" },
        NoicePopupmenuBorder = { bg = "#F2ECBC", fg = "#D5CEAC" },
        NoiceSplitBorder = { bg = "#F2ECBC", fg = "#D5CEAC" },
        FloatBorder = { bg = "#F2ECBC", fg = "#D5CEAC" },
        VertSplit = { bg = "#F2ECBC", fg = "#D5CEAC" },
        WinSeparator = { bg = "#F2ECBC", fg = "#D5CEAC" },
        NeoTreeWinSeparator = { bg = "#F2ECBC", fg = "#D5CEAC" },
        LineNr = { bg = "#F2ECBC" },
        FoldColumn = { bg = "#F2ECBC" },
        SignColumn = { bg = "#F2ECBC" },
        GitSigns = { bg = "#F2ECBC" },
        GitSignsAdd = { bg = "#F2ECBC", fg = "#76946A" },
        GitSignsDelete = { bg = "#F2ECBC", fg = "#C34043" },
        GitSignsChange = { bg = "#F2ECBC", fg = "#DCA561" },
      },
    },
  },
}

local function sync_gnome_theme()
  local result = vim.fn.system "gsettings get org.gnome.desktop.interface color-scheme"
  if vim.v.shell_error ~= 0 then return end

  result = result:gsub("['\n\r]", "")
  local new_bg = result == "prefer-dark" and "dark" or "light"

  local config = vim.g.theme_sync
  local mode_config = config and config[new_bg]

  local function apply_highlights(target_cs)
    local hl_by_theme = config and config.highlights and config.highlights[target_cs]
    local mode_hl = hl_by_theme and hl_by_theme[new_bg]
    if mode_hl then
      vim.defer_fn(function()
        for group, hl in pairs(mode_hl) do
          vim.api.nvim_set_hl(0, group, hl)
        end
      end, 50)
    end
  end

  vim.schedule(function()
    local target_cs
    if mode_config and mode_config.colorscheme and mode_config.colorscheme ~= vim.g.colors_name then
      target_cs = mode_config.colorscheme
      vim.cmd("colorscheme " .. target_cs)
    else
      target_cs = vim.g.colors_name
      if vim.o.background ~= new_bg then vim.o.background = new_bg end
    end
    apply_highlights(target_cs)
  end)
end

local lazy_stats = pcall(require, "lazy") and require("lazy").stats()
if lazy_stats and lazy_stats.times and lazy_stats.times.LazyDone then
  sync_gnome_theme()
else
  au("User", {
    group = augroup "theme_sync_start",
    pattern = "LazyDone",
    desc = "Initial GNOME theme sync after plugins load",
    once = true,
    callback = sync_gnome_theme,
  })
end

au("FocusGained", {
  group = augroup "theme_sync_focus",
  desc = "Re-sync GNOME theme on focus",
  callback = sync_gnome_theme,
})

local ok_pipe, stdout = pcall(vim.loop.new_pipe, false)
if ok_pipe and stdout then
  local handle = vim.loop.spawn("gsettings", {
    args = { "monitor", "org.gnome.desktop.interface", "color-scheme" },
    stdio = { nil, stdout, nil },
  }, function() stdout:close() end)
  if handle then
    stdout:read_start(function(err, data)
      if not err and data then vim.schedule(sync_gnome_theme) end
    end)
  end
end
