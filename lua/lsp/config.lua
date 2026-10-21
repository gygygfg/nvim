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

  -- 启动时自动用 Mason 安装缺失的 LSP 服务器 / 格式化工具。
  -- 说明：headless 环境（#nvim_list_uis() == 0）不触发；离线或安装失败仅
  -- 告警，绝不阻塞 Neovim 启动。任一子项置 false 即可关闭对应部分。
  auto_install = {
    -- 自动安装缺失的 LSP 服务器（依据 lsp_to_mason）
    servers = true,
    -- 自动安装缺失的格式化 / 检查工具（formatter_to_mason + linter_to_mason）
    formatters = true,
    -- 是否输出自动安装汇总通知（WARN 级别的失败提示不受此开关影响）
    notify = true,
  },

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
  -- java 不配置 CLI 格式化器：Termux(bionic) 无 glibc，google-java-format 原生
  -- 二进制不可用（ENOENT），改用 jdtls 内置格式化（见 format.lua 的 lsp_format）。
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
  -- codespell 会无条件读取「当前工作目录」下的 pyproject.toml；若其 TOML 非法
  -- （曾出现重复声明 [project]）会直接抛 TOMLDecodeError 崩溃。固定 cwd 到 state
  -- 目录（无 pyproject.toml）以隔离该风险。副作用：不再自动采用项目级配置。
  -- 注意：conform 要求 cwd 必须是 (config, ctx) -> string 的函数。
  codespell = { cwd = function()
    return vim.fn.stdpath("state")
  end },
}

return M
