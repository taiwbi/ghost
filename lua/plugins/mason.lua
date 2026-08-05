return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog", "MasonUpdate" },
    build = ":MasonUpdate",
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_uninstalled = "✗",
          package_pending = "⟳",
        },
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    lazy = false,
    opts = {
      run_on_start = true,
      ensure_installed = {
        "lua-language-server",
        "html-lsp",
        "laravel-ls",
        "css-lsp",
        "tailwindcss-language-server",
        "typescript-language-server",
        "json-lsp",
        "basedpyright",
        "rust-analyzer",

        "stylua",
        -- "pint", -- Not installing compose and php outside of docker for now
        "prettier",
        "blade-formatter",
        "beautysh",
        "xmlformatter",
        "pyink",
        "sql-formatter",

        "debugpy",
        "php-debug-adapter",
        "codelldb",

        "tree-sitter-cli",
      },
    },
  },
}
