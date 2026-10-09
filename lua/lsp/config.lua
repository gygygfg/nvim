-- ~/.config/nvim/lua/lsp/config.lua
-- LSP 相关静态数据表（纯数据，不含逻辑）

local M = {}

-- 全局配置选项
M.options = {
  -- 是否使用 nvim-lspconfig 插件（false 表示使用 Neovim 内置 LSP API）
  use_lspconfig = false,

  -- 是否启用调试日志
  debug = false,

  -- 是否在保存时自动格式化
  auto_format = true,

  -- 由外部插件（godotdev.nvim）托管的 LSP 服务器。
  -- 这些服务器仍会注册到 vim.lsp.config，但不由本模块 vim.lsp.enable，
  -- 避免与插件自身的启用逻辑产生重复客户端。
  external_lsp_servers = {
    godot_editor = true,
  },

  -- 内存限制（用于向各服务器注入 settings，不再作为启动门禁）
  memory_limit = {
    enabled = true,
    -- 最大并发 LSP 客户端数量（<=0 时按系统内存动态计算）
    -- 注意：仅用于内存相关配置的换算参考，不再限制客户端启动数量
    max_concurrent_clients = 0,
    -- 每个客户端最大内存（MB，<=0 时按系统内存动态计算）
    max_memory_per_client = 0,
    -- 最大 workspace 文件数量（<=0 时按系统内存动态计算）
    max_workspace_files = 0,
    -- 是否限制 workspace 大小
    limit_workspace_size = true,
  },
}

-- 文件类型 -> LSP 服务器映射（白名单，未列出的文件类型不启动 LSP）
M.filetype_mappings = {
  -- Web 开发
  javascript = { "ts_ls" },
  typescript = { "ts_ls" },
  javascriptreact = { "ts_ls" },
  typescriptreact = { "ts_ls" },
  html = { "html", "cssls" },
  css = { "cssls" },
  json = { "jsonls" },
  jsonc = { "jsonls" },
  yaml = { "yamlls" },

  -- 系统编程
  c = { "clangd" },
  cpp = { "clangd" },
  objc = { "clangd" },
  objcpp = { "clangd" },
  rust = { "rust_analyzer" },
  go = { "gopls" },

  -- 脚本语言
  lua = { "lua_ls" },
  python = { "pyright" },

  -- JVM
  java = { "jdtls" },

  -- Shell
  sh = { "bashls" },
  zsh = { "bashls" },
  bash = { "bashls" },

  -- Godot（由 godotdev.nvim 托管，见 plugins/godot.lua；此处登记以驱动
  -- 格式化与文档化映射，实际启用由 godotdev 通过 vim.lsp.enable("gdscript") 完成）
  gdscript = { "godot_editor" },
  gdresource = { "godot_editor" },
  gdshader = { "godot_editor" },
}

-- 文件类型 -> 格式化器（conform.nvim）
M.formatters_by_ft = {
  lua = { "stylua" },
  python = { "isort", "black" },
  javascript = { "prettierd", "prettier" },
  typescript = { "prettierd", "prettier" },
  javascriptreact = { "prettierd", "prettier" },
  typescriptreact = { "prettierd", "prettier" },
  html = { "prettierd", "prettier" },
  css = { "prettierd", "prettier" },
  json = { "prettierd", "prettier" },
  yaml = { "yamlfmt" },
  markdown = { "prettierd", "prettier" },
  bash = { "shfmt" },
  sh = { "shfmt" },
  c = { "clang-format" },
  cpp = { "clang-format" },
  go = { "gofumpt", "goimports" },
  rust = { "rustfmt" },
  java = { "google-java-format" },
  sql = { "sql-formatter" },
  tex = { "latexindent" },
  -- Godot（conform 内置 gdscript-formatter）
  gdscript = { "gdscript-formatter" },
  gdresource = { "gdscript-formatter" },
  gdshader = { "gdscript-formatter" },
  ["*"] = { "codespell" }, -- 所有文件类型做拼写检查
}

-- 跳过 LSP 与格式化的文件类型
M.skip_filetypes = {
  notify = true,
  NvimTree = true,
  TelescopePrompt = true,
  packer = true,
  help = true,
  qf = true,
  terminal = true,
  codecompanion = true,
  neoai = true,
  [""] = true,
}

-- LSP 服务器 -> Mason 包名
M.lsp_to_mason = {
  lua_ls = "lua-language-server",
  pyright = "pyright",
  ts_ls = "typescript-language-server",
  html = "html-lsp",
  cssls = "css-lsp",
  jsonls = "json-lsp",
  yamlls = "yaml-language-server",
  bashls = "bash-language-server",
  clangd = "clangd",
  gopls = "gopls",
  rust_analyzer = "rust-analyzer",
  jdtls = "jdtls",
}

-- 格式化工具 -> Mason 包名
M.formatter_to_mason = {
  stylua = "stylua",
  prettier = "prettier",
  prettierd = "prettierd",
  black = "black",
  isort = "isort",
  yamlfmt = "yamlfmt",
  shfmt = "shfmt",
  ["clang-format"] = "clang-format",
  gofumpt = "gofumpt",
  goimports = "gofmt",
  rustfmt = "rustfmt",
  ["google-java-format"] = "google-java-format",
  ["sql-formatter"] = "sql-formatter",
  latexindent = "latexindent",
  codespell = "codespell",
}

-- 检查工具（linter）-> Mason 包名
M.linter_to_mason = {
  shellcheck = "shellcheck",
}

-- 各服务器默认启动命令（当 configs/ 下配置未提供 cmd 时使用）
M.default_cmds = {
  lua_ls = { "lua-language-server" },
  pyright = { "pyright-langserver", "--stdio" },
  ts_ls = { "typescript-language-server", "--stdio" },
  html = { "vscode-html-language-server", "--stdio" },
  cssls = { "vscode-css-language-server", "--stdio" },
  jsonls = { "vscode-json-language-server", "--stdio" },
  yamlls = { "yaml-language-server", "--stdio" },
  bashls = { "bash-language-server", "start" },
  clangd = { "clangd" },
  gopls = { "gopls" },
  rust_analyzer = { "rust-analyzer" },
}

-- conform.nvim 各格式化器参数
M.formatter_args = {
  stylua = { prepend_args = { "--indent-width", "2", "--indent-type", "Spaces" } },
  prettier = { prepend_args = { "--single-quote", "--jsx-single-quote", "--print-width", "100" } },
  prettierd = { prepend_args = { "--single-quote", "--jsx-single-quote", "--print-width", "100" } },
  black = { prepend_args = { "--line-length", "88" } },
  isort = { prepend_args = { "--profile", "black" } },
  shfmt = { prepend_args = { "-i", "2" } },
  ["clang-format"] = { prepend_args = { "--style", "{BasedOnStyle: Google, IndentWidth: 2}" } },
}

return M
