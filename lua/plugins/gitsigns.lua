local function stage_buffer()
  local gs = require "gitsigns"
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local stage_tracked_buffer = function()
    if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_call(bufnr, gs.stage_buffer) end
  end

  if filename == "" then return stage_tracked_buffer() end

  local root = vim.fs.root(filename, { ".git" })
  if not root then return stage_tracked_buffer() end

  vim.system({ "git", "status", "--porcelain=v1", "--untracked-files=normal", "--", filename }, {
    cwd = root,
    text = true,
  }, function(result)
    if result.code ~= 0 then
      return vim.schedule(function() vim.notify(result.stderr, vim.log.levels.ERROR) end)
    end

    if result.stdout:match "^%?%?" then
      vim.system({ "git", "add", "--", filename }, { cwd = root }, function(add_result)
        vim.schedule(function()
          if add_result.code ~= 0 then
            vim.notify(add_result.stderr, vim.log.levels.ERROR)
          else
            gs.refresh()
          end
        end)
      end)
    else
      vim.schedule(stage_tracked_buffer)
    end
  end)
end

local function unstage_buffer()
  local gs = require "gitsigns"
  local filename = vim.api.nvim_buf_get_name(0)

  if filename == "" then return vim.notify("Current buffer has no file", vim.log.levels.WARN) end

  local root = vim.fs.root(filename, { ".git" })
  if not root then return vim.notify("Current file is not in a Git repository", vim.log.levels.WARN) end

  vim.system({ "git", "restore", "--staged", "--", filename }, { cwd = root, text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify(result.stderr, vim.log.levels.ERROR)
      else
        gs.refresh()
      end
    end)
  end)
end

return {
  "lewis6991/gitsigns.nvim",
  enabled = vim.fn.executable "git" == 1,
  event = { "BufReadPre", "BufNewFile" },
  init = function()
    vim.keymap.set("n", "<Leader>gS", stage_buffer, { desc = "Stage Git buffer (including untracked)" })
    vim.keymap.set("n", "<Leader>gU", unstage_buffer, { desc = "Unstage Git buffer" })
  end,
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    signs_staged = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    on_attach = function(bufnr)
      local gs = require "gitsigns"
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      map("n", "<Leader>gl", gs.blame_line, "View Git blame")
      map("n", "<Leader>gL", function() gs.blame_line { full = true } end, "View full Git blame")
      map("n", "<Leader>gp", gs.preview_hunk_inline, "Preview Git hunk")
      map("n", "<Leader>gr", gs.reset_hunk, "Reset Git hunk")
      map("v", "<Leader>gr", function() gs.reset_hunk { vim.fn.line ".", vim.fn.line "v" } end, "Reset Git hunk")
      map("n", "<Leader>gR", gs.reset_buffer, "Reset Git buffer")
      map("n", "<Leader>gs", gs.stage_hunk, "Stage/Unstage Git hunk")
      map("v", "<Leader>gs", function() gs.stage_hunk { vim.fn.line ".", vim.fn.line "v" } end, "Stage Git hunk")
      map("n", "<Leader>gd", gs.diffthis, "View Git diff")

      map("n", "[G", function() gs.nav_hunk "first" end, "First Git hunk")
      map("n", "]G", function() gs.nav_hunk "last" end, "Last Git hunk")
      map("n", "]g", function() gs.nav_hunk "next" end, "Next Git hunk")
      map("n", "[g", function() gs.nav_hunk "prev" end, "Previous Git hunk")

      for _, mode in ipairs { "o", "x" } do
        map(mode, "ig", ":<C-U>Gitsigns select_hunk<CR>", "inside Git hunk")
      end
    end,
  },
}
