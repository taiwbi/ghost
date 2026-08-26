return {
  {
    "kndndrj/nvim-dbee",
    cmd = "Dbee",
    dependencies = { "MunifTanjim/nui.nvim" },
    build = function() require("dbee").install() end,
    opts = function()
      return {
        sources = {
          -- Sources should be added with GO-Style DSN strings
          -- username:password@tcp(127.0.0.1:3306)/dbname
          require("dbee.sources").FileSource:new(vim.fn.stdpath "state" .. "/dbee/persistence.json"),
        },
      }
    end,
  },
  {
    "MattiasMTS/cmp-dbee",
    dependencies = { "kndndrj/nvim-dbee" },
    ft = "sql",
    opts = {},
  },
}
