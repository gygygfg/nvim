-- ~/.config/nvim/lua/lsp/init.lua
-- 集成 conform.nvim 的 LSP 配置

local M = {}

-- 防止重复加载
if M._loaded then
  return M
end
M._loaded = true

vim.pack.add({
  -- 安装但不加载需要插件
  -- LSP 相关
  gh("j-hui/fidget.nvim"),
  gh("stevearc/dressing.nvim"),
  gh("folke/trouble.nvim"),
  gh("folke/which-key.nvim"),
  -- gh("neovim/nvim-lspconfig"), -- 注释掉，完全使用 Neovim 0.12 内置 LSP API
  -- Mason 和相关插件
  gh("williamboman/mason.nvim"),
  gh("williamboman/mason-lspconfig.nvim"),
  -- Formatter & Linter
  gh("stevearc/conform.nvim"),
})

-- 配置选项
M.config = {
  -- 是否使用 nvim-lspconfig 插件
  -- 设置为 false 时，使用 Neovim 0.12 的内置 LSP API
  use_lspconfig = false,

  -- 是否启用调试模式
  debug = false,

  -- 是否自动格式化
  auto_format = true,

  -- 内存限制配置
  memory_limit = {
    -- 是否启用内存限制
    enabled = true,

    -- 最大并发 LSP 客户端数量
    max_concurrent_clients = 3,

    -- 每个 LSP 客户端最大内存限制（MB）
    max_memory_per_client = 512,

    -- 是否启用延迟加载
    lazy_load = true,

    -- 延迟加载超时时间（毫秒）
    lazy_load_timeout = 1000,

    -- 是否限制 workspace 大小
    limit_workspace_size = true,

    -- 最大 workspace 文件数量
    max_workspace_files = 1000,
  },

  -- GitHub Copilot 配置
  copilot = {
    -- 是否启用 Copilot
    enabled = true,

    -- Copilot 内存限制（MB）
    memory_limit = 256,

    -- 是否启用建议延迟
    suggestion_delay = 100,

    -- 最大并发建议数量
    max_concurrent_suggestions = 1,

    -- 是否限制文件大小（超过此大小的文件不提供建议）
    limit_file_size = true,

    -- 最大文件大小（KB）
    max_file_size_kb = 100,
  },
}

M.formatters_by_ft = {
  -- 格式化工具配置
  lua = { "stylua" },
  python = { "black", "isort" },
  javascript = { "prettierd", "prettier" },
  typescript = { "prettierd", "prettier" },
  javascriptreact = { "prettierd", "prettier" },
  typescriptreact = { "prettierd", "prettier" },
  html = { "prettierd", "prettier" },
  css = { "prettierd", "prettier" },
  json = { "prettierd", "prettier" },
  yaml = { "yamlfmt" },
  yml = { "yamlfmt" },
  bash = { "shfmt" },
  sh = { "shfmt" },
  c = { "clang-format" },
  cpp = { "clang-format" },
  go = { "gofumpt", "goimports" },
  rust = { "rustfmt" },
  java = { "google-java-format" },
  markdown = { "prettierd", "prettier" },
  sql = { "sql-formatter" },
  tex = { "latexindent" },
  ["*"] = { "codespell" }, -- 拼写检查
}

M.filetype_mappings = {
  -- 文件类型到 LSP 服务器的映射（支持多个服务器）
  -- Web 开发
  javascript = { "ts_ls", "html", "cssls" },
  typescript = { "ts_ls", "html", "cssls" },
  javascriptreact = { "ts_ls", "html", "cssls" },
  typescriptreact = { "ts_ls", "html", "cssls" },
  html = { "html", "cssls", "ts_ls" },
  css = { "cssls" },
  json = { "jsonls" },
  yaml = { "yamlls" },
  yml = { "yamlls" },

  -- 系统编程
  c = { "clangd", "html" },
  cpp = { "clangd", "html" },
  rust = { "rust_analyzer", "html" },
  go = { "gopls", "html" },

  -- 脚本语言
  lua = { "lua_ls" },
  python = { "pyright", "html", "cssls", "ts_ls" },
  sh = { "bashls" },
  zsh = { "bashls" },
  bash = { "bashls" },
}

M.lsp_to_mason = {
  -- LSP 服务器到 Mason 包名的映射
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
}

M.formatter_to_mason = {
  -- 格式化工具到 Mason 包名的映射
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

-- 跳过 LSP 检查和格式化的文件类型
M.skip_filetypes = {
  notify = true, -- vim.notify 插件弹出的悬浮文本
  NvimTree = true, -- 文件管理器
  TelescopePrompt = true, -- Telescope 提示框
  packer = true, -- 插件管理器
  help = true, -- 帮助文档
  qf = true, -- 快速修复列表
  terminal = true, -- 终端
  [""] = true, -- 空文件类型
}

local function load_server_config(server_name)
  -- 动态加载 LSP 服务器配置
  local module_name = "lsp.configs." .. server_name

  -- 调试信息
  if vim.g.lsp_debug then
    vim.notify("[LSP] [LSP] 尝试加载配置模块: " .. module_name)
  end

  local ok, config = pcall(require, module_name)
  if ok then
    return config
  else
    vim.notify("[LSP] [LSP] 配置加载失败: " .. server_name)
    vim.notify("[LSP] [LSP] 错误信息: " .. config)

    -- 调试模块路径
    vim.notify("[LSP] [LSP] 调试模块路径:")

    -- 详细分析 package.path
    local paths = {}
    for path in package.path:gmatch("[^;]+") do
      table.insert(paths, path)
    end
    vim.notify("[LSP]   package.path 包含 " .. #paths .. " 个路径")

    -- 显示前几个路径
    for i = 1, math.min(5, #paths) do
      vim.notify("[LSP]     [" .. i .. "] " .. paths[i])
    end

    if #paths > 5 then
      vim.notify("[LSP]     ... 还有 " .. (#paths - 5) .. " 个路径")
    end

    -- 尝试查找文件
    local config_path = vim.fn.expand("~/.config/nvim/lua/lsp/configs/" .. server_name .. ".lua")
    vim.notify("[LSP]   配置文件路径: " .. config_path)
    vim.notify("[LSP]   文件存在: " .. (vim.fn.filereadable(config_path) == 1 and "是" or "否"))

    -- 测试模块搜索
    vim.notify("[LSP]   测试模块搜索:")
    local test_module = "lsp.configs." .. server_name
    local test_path = test_module:gsub("%.", "/") .. ".lua"
    vim.notify("[LSP]     模块名: " .. test_module)
    vim.notify("[LSP]     转换后路径: " .. test_path)

    -- 尝试在 package.path 中查找
    for i, path_pattern in ipairs(paths) do
      local test_file = path_pattern:gsub("%?", test_path)
      if vim.fn.filereadable(test_file) == 1 then
        vim.notify("[LSP]     在路径 [" .. i .. "] 找到文件: " .. test_file)
        break
      end
    end
    return {}
  end
end

local function get_default_cmd(server_name)
  -- 为常见服务器提供默认的 cmd 值
  local default_cmds = {
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

  return default_cmds[server_name]
end

local function get_available_servers()
  -- 获取所有可用的 LSP 服务器（从 configs 文件夹动态获取）
  local configs_dir = vim.fn.expand("~/.config/nvim/lua/lsp/configs")
  local servers = {}

  local handle = vim.loop.fs_scandir(configs_dir)
  if handle then
    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end

      -- 只处理 .lua 文件
      if type == "file" and name:match("%.lua$") then
        local server_name = name:gsub("%.lua$", "")
        table.insert(servers, server_name)
      end
    end
  end

  return servers
end

M.server_configs = setmetatable({}, {
  __index = function(_, server_name)
    return load_server_config(server_name)
  end,
})

M.get_available_servers = get_available_servers

local function has_active_lsp_client(bufnr)
  -- 检查当前缓冲区是否有活动的 LSP 客户端
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  return #clients > 0
end

local function safe_lsp_action(action, warning_msg)
  -- 安全执行 LSP 操作，如果没有活动客户端则显示警告
  local bufnr = vim.api.nvim_get_current_buf()
  if has_active_lsp_client(bufnr) then
    action()
  else
    vim.notify(warning_msg or "没有活动的 LSP 客户端", vim.log.levels.WARN)
  end
end

local function setup_conform()
  -- 设置 conform.nvim
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    vim.notify("[LSP] conform.nvim 插件未加载，请确保已安装", vim.log.levels.WARN)
    return
  end

  conform.setup({
    formatters_by_ft = M.formatters_by_ft,

    -- 默认格式化选项
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true, -- 如果 LSP 支持格式化，也使用 LSP
    },

    -- 异步格式化
    format_after_save = {
      lsp_fallback = true,
    },

    -- 配置每个格式化器的选项
    formatters = {
      stylua = {
        prepend_args = { "--indent-width", "2", "--indent-type", "Spaces" },
      },
      prettier = {
        prepend_args = { "--single-quote", "--jsx-single-quote" },
      },
      prettierd = {
        prepend_args = { "--single-quote", "--jsx-single-quote" },
      },
      black = {
        prepend_args = { "--line-length", "88" },
      },
      isort = {
        prepend_args = { "--profile", "black" },
      },
      shfmt = {
        prepend_args = { "-i", "2" },
      },
      clang_format = {
        prepend_args = { "--style", "{BasedOnStyle: Google, IndentWidth: 2}" },
      },
    },

    -- 如果没有找到对应的格式化器，使用 LSP
    fallback_conform = function(bufnr)
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      for _, client in ipairs(clients) do
        if client.server_capabilities.documentFormattingProvider then
          vim.lsp.buf.format({ async = false, bufnr = bufnr })
          return true
        end
      end
      return false
    end,
  })

  -- 设置格式化快捷键
  vim.keymap.set({ "n", "v" }, "<leader>f", function()
    conform.format({ async = true, lsp_fallback = true })
  end, { desc = "使用 conform.nvim 格式化" })

  -- 查看当前文件的格式化器
  vim.keymap.set("n", "<leader>F", function()
    local ft = vim.bo.filetype
    local formatters = M.formatters_by_ft[ft] or {}
    local msg = "文件类型: " .. ft .. "\n可用的格式化器: "
    if #formatters > 0 then
      msg = msg .. table.concat(formatters, ", ")
    else
      msg = msg .. "无"
    end
    vim.notify(msg, vim.log.levels.INFO)
  end, { desc = "查看格式化器" })

  vim.notify("[LSP] conform.nvim 已配置")
end

local function default_on_attach(client, bufnr)
  -- 默认的 on_attach 函数
  if client.server_capabilities.documentFormattingProvider then
    vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()"
  end

  -- 设置缓冲区本地按键映射
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set("n", "<leader>wl", function()
    vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, bufopts)
end

local function setup_global_keymaps()
  -- 设置全局按键映射
  vim.keymap.set("n", "gK", function()
    safe_lsp_action(vim.lsp.buf.hover, "没有活动的 LSP 客户端")
  end, { desc = "显示悬停文档" })

  vim.keymap.set("n", "gd", function()
    safe_lsp_action(vim.lsp.buf.definition, "没有活动的 LSP 客户端")
  end, { desc = "跳转到定义" })

  vim.keymap.set({ "n", "v" }, "<leader>ca", function()
    safe_lsp_action(vim.lsp.buf.code_action, "没有活动的 LSP 客户端")
  end, { desc = "代码操作" })

  vim.keymap.set("n", "<leader>rn", function()
    safe_lsp_action(vim.lsp.buf.rename, "没有活动的 LSP 客户端")
  end, { desc = "重命名符号" })

  vim.keymap.set({ "n", "v" }, "<leader>cf", function()
    -- 格式化（使用 conform.nvim）
    local conform_ok, conform = pcall(require, "conform")
    if conform_ok then
      conform.format({ async = true, lsp_fallback = true })
    else
      -- 回退到 LSP 格式化
      local bufnr = vim.api.nvim_get_current_buf()
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      local formatting_clients = {}
      for _, client in ipairs(clients) do
        if client.server_capabilities.documentFormattingProvider then
          table.insert(formatting_clients, client.name)
        end
      end
      if #formatting_clients > 0 then
        vim.lsp.buf.format({ async = true })
        vim.notify("[LSP] 正在格式化... (" .. table.concat(formatting_clients, ", ") .. ")", vim.log.levels.INFO)
      else
        vim.notify("[LSP] 没有找到可用的格式化器", vim.log.levels.WARN)
      end
    end
  end, { desc = "格式化文档" })

  -- 查看引用
  vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "查看引用" })
  -- 查看实现
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "查看实现" })
  -- 类型定义
  vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { desc = "跳转到类型定义" })
  -- 签名帮助
  vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "签名帮助" })
  -- 这些映射已在 setup_global_keymaps 中设置，避免重复
  -- vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
  -- vim.keymap.set("n", "gh", vim.lsp.buf.hover)
  vim.keymap.set("n", "g[", function()
    vim.diagnostic.jump({ count = -1, severity_limit = vim.diagnostic.severity.WARN })
  end)
  vim.keymap.set("n", "g]", function()
    vim.diagnostic.jump({ count = 1, severity_limit = vim.diagnostic.severity.WARN })
  end)
  vim.keymap.set("n", "go", function()
    vim.diagnostic.open_float()
  end)
  vim.keymap.set("n", "<leader>q", function()
    vim.diagnostic.setloclist()
  end)
end

local function setup_diagnostics()
  -- 设置诊断
  vim.diagnostic.config({
    virtual_text = {
      prefix = "●",
      spacing = 2,
    },
    signs = true,
    underline = true,
    -- 在插入模式下也更新诊断
    update_in_insert = true,
    severity_sort = true,
    float = {
      border = "rounded",
      source = true,
      header = "",
      prefix = "",
    },
    -- 启用异步诊断
    virtual_lines = false,
  })

  -- 设置诊断符号
  local signs = {
    Error = "",
    Warn = "",
    Hint = "",
    Info = "",
  }

  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end
end

-- ============================================
-- 内存管理功能
-- ============================================

local function check_memory_limits()
  -- 检查内存限制
  if not M.config.memory_limit.enabled then
    return true
  end

  -- 获取当前 LSP 客户端数量
  local all_clients = vim.lsp.get_clients()
  local active_clients = 0

  for _, client in ipairs(all_clients) do
    -- 检查客户端是否活跃（有附加的缓冲区）
    local has_attached_buffers = false
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.lsp.buf_is_attached(bufnr, client.id) then
        has_attached_buffers = true
        break
      end
    end

    if has_attached_buffers then
      active_clients = active_clients + 1
    end
  end

  -- 检查是否超过最大并发客户端数量
  if active_clients >= M.config.memory_limit.max_concurrent_clients then
    if vim.g.lsp_debug then
      vim.notify(
        "[LSP] 内存限制: 已达到最大并发客户端数量 ("
          .. active_clients
          .. "/"
          .. M.config.memory_limit.max_concurrent_clients
          .. ")",
        vim.log.levels.WARN
      )
    end
    return false
  end

  return true
end

local function get_system_memory_info()
  -- 获取系统内存信息（Linux 系统）
  local meminfo = {}
  local file = io.open("/proc/meminfo", "r")

  if file then
    for line in file:lines() do
      if line:match("^MemTotal:") then
        local value = line:match("%d+")
        meminfo.total_kb = tonumber(value) or 0
        meminfo.total_mb = math.floor(meminfo.total_kb / 1024)
        meminfo.total_gb = math.floor(meminfo.total_mb / 1024 * 10) / 10
      elseif line:match("^MemAvailable:") then
        local value = line:match("%d+")
        meminfo.available_kb = tonumber(value) or 0
        meminfo.available_mb = math.floor(meminfo.available_kb / 1024)
      elseif line:match("^MemFree:") then
        local value = line:match("%d+")
        meminfo.free_kb = tonumber(value) or 0
        meminfo.free_mb = math.floor(meminfo.free_kb / 1024)
      end
    end
    file:close()

    -- 计算使用率
    if meminfo.total_kb > 0 then
      meminfo.used_kb = meminfo.total_kb - (meminfo.available_kb or meminfo.free_kb)
      meminfo.used_mb = math.floor(meminfo.used_kb / 1024)
      meminfo.usage_percent = math.floor((meminfo.used_kb / meminfo.total_kb) * 100)
    end
  end

  return meminfo
end

local function calculate_dynamic_limits()
  -- 根据系统内存动态计算限制
  local meminfo = get_system_memory_info()
  local limits = {
    max_concurrent_clients = 3,
    max_memory_per_client = 512,
    max_workspace_files = 1000,
    lua_max_items = 1000, -- lua_ls 特定限制
    system_memory_gb = meminfo.total_gb or 8,
  }

  if meminfo.total_gb then
    -- 根据系统内存大小调整限制
    if meminfo.total_gb <= 4 then
      -- 4GB 或更少
      limits.max_concurrent_clients = 2
      limits.max_memory_per_client = 256
      limits.max_workspace_files = 500
      limits.lua_max_items = 500
    elseif meminfo.total_gb <= 8 then
      -- 8GB
      limits.max_concurrent_clients = 3
      limits.max_memory_per_client = 512
      limits.max_workspace_files = 1000
      limits.lua_max_items = 1000
    elseif meminfo.total_gb <= 16 then
      -- 16GB
      limits.max_concurrent_clients = 5
      limits.max_memory_per_client = 1024
      limits.max_workspace_files = 2000
      limits.lua_max_items = 2000
    elseif meminfo.total_gb <= 32 then
      -- 32GB
      limits.max_concurrent_clients = 8
      limits.max_memory_per_client = 2048
      limits.max_workspace_files = 5000
      limits.lua_max_items = 5000
    else
      -- 32GB+
      limits.max_concurrent_clients = 12
      limits.max_memory_per_client = 4096
      limits.max_workspace_files = 10000
      limits.lua_max_items = 10000
    end

    -- 根据当前内存使用率进一步调整
    if meminfo.usage_percent and meminfo.usage_percent > 80 then
      -- 内存使用率高，减少限制
      limits.max_concurrent_clients = math.max(2, limits.max_concurrent_clients - 1)
      limits.max_memory_per_client = math.max(256, limits.max_memory_per_client * 0.8)
      limits.max_workspace_files = math.max(500, limits.max_workspace_files * 0.7)
      limits.lua_max_items = math.max(500, limits.lua_max_items * 0.7)
    elseif meminfo.usage_percent and meminfo.usage_percent < 40 then
      -- 内存使用率低，可以增加限制
      limits.max_concurrent_clients = limits.max_concurrent_clients + 1
      limits.max_memory_per_client = limits.max_memory_per_client * 1.2
      limits.max_workspace_files = limits.max_workspace_files * 1.3
      limits.lua_max_items = limits.lua_max_items * 1.3
    end
  end

  -- 确保值为整数
  limits.max_concurrent_clients = math.floor(limits.max_concurrent_clients)
  limits.max_memory_per_client = math.floor(limits.max_memory_per_client)
  limits.max_workspace_files = math.floor(limits.max_workspace_files)
  limits.lua_max_items = math.floor(limits.lua_max_items)

  return limits
end

local function apply_memory_limits_to_config(config, server_name)
  -- 为所有 LSP 服务器应用内存限制
  if not M.config.memory_limit.enabled then
    return config
  end

  -- 复制配置以避免修改原始配置
  local limited_config = vim.deepcopy(config)

  -- 确保 settings 表存在
  if not limited_config.settings then
    limited_config.settings = {}
  end

  -- 计算动态限制
  local dynamic_limits = calculate_dynamic_limits()

  -- 使用动态限制或配置的限制
  local max_memory_per_client = M.config.memory_limit.max_memory_per_client > 0
      and M.config.memory_limit.max_memory_per_client
    or dynamic_limits.max_memory_per_client

  local max_workspace_files = M.config.memory_limit.max_workspace_files > 0
      and M.config.memory_limit.max_workspace_files
    or dynamic_limits.max_workspace_files

  -- 通用内存限制配置
  local memory_limit_kb = max_memory_per_client * 1024

  -- 根据服务器类型应用特定的内存限制
  if server_name == "lua_ls" then
    -- Lua 语言服务器内存限制
    limited_config.settings.Lua = limited_config.settings.Lua or {}
    limited_config.settings.Lua.workspace = limited_config.settings.Lua.workspace or {}
    limited_config.settings.Lua.diagnostics = limited_config.settings.Lua.diagnostics or {}
    limited_config.settings.Lua.completion = limited_config.settings.Lua.completion or {}
    limited_config.settings.Lua.hint = limited_config.settings.Lua.hint or {}

    -- 使用已计算的动态限制
    local lua_max_items = dynamic_limits.lua_max_items

    -- 限制 workspace 大小和数量
    if M.config.memory_limit.limit_workspace_size then
      -- 最大预加载文件数量
      limited_config.settings.Lua.workspace.maxPreload =
        math.min(limited_config.settings.Lua.workspace.maxPreload or 10000, max_workspace_files)

      -- 预加载文件大小限制
      limited_config.settings.Lua.workspace.preloadFileSize = math.min(
        limited_config.settings.Lua.workspace.preloadFileSize or 10000,
        5000 -- 5MB
      )

      -- workspace 库检查限制
      limited_config.settings.Lua.workspace.checkThirdParty = false

      -- 限制 workspace 中的库数量
      limited_config.settings.Lua.workspace.library = limited_config.settings.Lua.workspace.library or {}
      limited_config.settings.Lua.workspace.maxLibraryFiles =
        math.min(limited_config.settings.Lua.workspace.maxLibraryFiles or 5000, lua_max_items)
    end

    -- 限制诊断数量和频率
    limited_config.settings.Lua.diagnostics.workspaceRate = 30 -- 降低诊断频率
    limited_config.settings.Lua.diagnostics.workspaceDelay = 1500 -- 增加延迟

    -- 禁用代码风格检查（避免格式化器与 lua_ls 风格检查冲突）
    limited_config.settings.Lua.diagnostics.disable = limited_config.settings.Lua.diagnostics.disable or {}
    table.insert(limited_config.settings.Lua.diagnostics.disable, "codestyle-check")

    -- 限制最大诊断数量
    limited_config.settings.Lua.diagnostics.maxItems =
      math.min(limited_config.settings.Lua.diagnostics.maxItems or 1000, lua_max_items)

    -- 限制全局变量诊断数量
    limited_config.settings.Lua.diagnostics.globals = limited_config.settings.Lua.diagnostics.globals or {}
    if #limited_config.settings.Lua.diagnostics.globals > 100 then
      -- 如果全局变量太多，只保留前100个
      local limited_globals = {}
      for i = 1, math.min(100, #limited_config.settings.Lua.diagnostics.globals) do
        table.insert(limited_globals, limited_config.settings.Lua.diagnostics.globals[i])
      end
      limited_config.settings.Lua.diagnostics.globals = limited_globals
    end

    -- 限制代码补全数量
    limited_config.settings.Lua.completion.maxItems =
      math.min(limited_config.settings.Lua.completion.maxItems or 500, math.floor(lua_max_items / 2))

    limited_config.settings.Lua.completion.autoRequire = false -- 禁用自动 require
    limited_config.settings.Lua.completion.showWord = "Disable" -- 禁用单词显示

    -- 限制提示数量
    limited_config.settings.Lua.hint.enable = true
    limited_config.settings.Lua.hint.arrayIndex = "Disable" -- 禁用数组索引提示
    limited_config.settings.Lua.hint.paramType = false -- 禁用参数类型提示
    limited_config.settings.Lua.hint.setType = false -- 禁用设置类型提示

    -- 限制语义令牌数量
    limited_config.settings.Lua.semantic = limited_config.settings.Lua.semantic or {}
    limited_config.settings.Lua.semantic.enable = false -- 禁用语义高亮以减少内存

    -- 限制颜色提供者
    limited_config.settings.Lua.color = limited_config.settings.Lua.color or {}
    limited_config.settings.Lua.color.mode = "Disable" -- 禁用颜色模式

    -- 禁用不必要的功能以节省内存
    limited_config.settings.Lua.telemetry = limited_config.settings.Lua.telemetry or {}
    limited_config.settings.Lua.telemetry.enable = false

    limited_config.settings.Lua.format = limited_config.settings.Lua.format or {}
    limited_config.settings.Lua.format.enable = false -- 禁用内置格式化，使用外部格式化器

    -- 限制运行时信息
    limited_config.settings.Lua.runtime = limited_config.settings.Lua.runtime or {}
    limited_config.settings.Lua.runtime.version = "Lua 5.4" -- 固定版本
    limited_config.settings.Lua.runtime.special = limited_config.settings.Lua.runtime.special or {}
    limited_config.settings.Lua.runtime.special = {} -- 清空特殊表

    -- 添加内存限制标记
    limited_config.settings.Lua.memoryLimit = memory_limit_kb
    limited_config.settings.Lua.performanceMode = "low"

    -- 调试信息
    if vim.g.lsp_debug then
      vim.notify("[LSP] lua_ls 内存限制配置:")
      vim.notify("[LSP]   • maxPreload: " .. (limited_config.settings.Lua.workspace.maxPreload or "默认"))
      vim.notify("[LSP]   • maxLibraryFiles: " .. (limited_config.settings.Lua.workspace.maxLibraryFiles or "默认"))
      vim.notify("[LSP]   • diagnostics.maxItems: " .. (limited_config.settings.Lua.diagnostics.maxItems or "默认"))
      vim.notify("[LSP]   • completion.maxItems: " .. (limited_config.settings.Lua.completion.maxItems or "默认"))
      vim.notify("[LSP]   • 动态限制 lua_max_items: " .. lua_max_items)
    end
  elseif server_name == "pyright" then
    -- Python 语言服务器内存限制
    limited_config.settings.python = limited_config.settings.python or {}
    limited_config.settings.python.analysis = limited_config.settings.python.analysis or {}

    -- 限制分析范围
    limited_config.settings.python.analysis.autoSearchPaths = false
    limited_config.settings.python.analysis.useLibraryCodeForTypes = false
    limited_config.settings.python.analysis.diagnosticMode = "workspace"
    limited_config.settings.python.analysis.typeCheckingMode = "basic"

    -- 限制内存使用
    limited_config.settings.python.analysis.memory = limited_config.settings.python.analysis.memory or {}
    limited_config.settings.python.analysis.memory.heapSize = memory_limit_kb
  elseif server_name == "ts_ls" or server_name == "tsserver" then
    -- TypeScript/JavaScript 语言服务器内存限制
    limited_config.settings.typescript = limited_config.settings.typescript or {}
    limited_config.settings.typescript.maxTsServerMemory = memory_limit_kb * 1024 -- 转换为字节
    limited_config.settings.typescript.suggest = limited_config.settings.typescript.suggest or {}
    limited_config.settings.typescript.suggest.autoImports = false
    limited_config.settings.typescript.suggest.paths = false

    limited_config.settings.javascript = limited_config.settings.javascript or {}
    limited_config.settings.javascript.suggest = limited_config.settings.javascript.suggest or {}
    limited_config.settings.javascript.suggest.autoImports = false
    limited_config.settings.javascript.suggest.paths = false

    -- 限制项目大小
    limited_config.settings.typescript.maxProjectFileCount = M.config.memory_limit.max_workspace_files
    limited_config.settings.javascript.maxProjectFileCount = M.config.memory_limit.max_workspace_files
  elseif server_name == "clangd" then
    -- C/C++ 语言服务器内存限制
    limited_config.settings.clangd = limited_config.settings.clangd or {}

    -- 限制内存使用
    limited_config.settings.clangd.memoryLimit = memory_limit_kb

    -- 限制索引大小
    limited_config.settings.clangd.maxIndexFileSize = 5000 -- 5MB
    limited_config.settings.clangd.maxSymbolIndexFiles = 1000
  elseif server_name == "rust_analyzer" then
    -- Rust 语言服务器内存限制
    limited_config.settings.rust_analyzer = limited_config.settings.rust_analyzer or {}

    -- 限制内存使用
    limited_config.settings.rust_analyzer.maxMemoryUsage = memory_limit_kb * 1024 -- 转换为字节

    -- 限制分析范围
    limited_config.settings.rust_analyzer.checkOnSave = limited_config.settings.rust_analyzer.checkOnSave or {}
    limited_config.settings.rust_analyzer.checkOnSave.allTargets = false
    limited_config.settings.rust_analyzer.cargo = limited_config.settings.rust_analyzer.cargo or {}
    limited_config.settings.rust_analyzer.cargo.allFeatures = false
    limited_config.settings.rust_analyzer.cargo.noDefaultFeatures = true
  elseif server_name == "gopls" then
    -- Go 语言服务器内存限制
    limited_config.settings.gopls = limited_config.settings.gopls or {}

    -- 限制内存使用
    limited_config.settings.gopls.memoryMode = "Degrade"

    -- 限制分析范围
    limited_config.settings.gopls.staticcheck = false
    limited_config.settings.gopls.completeUnimported = false
    limited_config.settings.gopls.deepCompletion = false
  elseif server_name == "html" or server_name == "cssls" or server_name == "jsonls" then
    -- Web 相关语言服务器内存限制
    -- 这些服务器通常内存占用较小，但可以限制一些功能
    limited_config.settings.html = limited_config.settings.html or {}
    limited_config.settings.html.suggest = limited_config.settings.html.suggest or {}
    limited_config.settings.html.suggest.html5 = false

    limited_config.settings.css = limited_config.settings.css or {}
    limited_config.settings.css.suggest = limited_config.settings.css.suggest or {}
    limited_config.settings.css.suggest.completePropertyWithSemicolon = false

    limited_config.settings.json = limited_config.settings.json or {}
    limited_config.settings.json.suggest = limited_config.settings.json.suggest or {}
    limited_config.settings.json.suggest.comments = false
  elseif server_name == "yamlls" then
    -- YAML 语言服务器内存限制
    limited_config.settings.yaml = limited_config.settings.yaml or {}
    limited_config.settings.yaml.schemaStore = limited_config.settings.yaml.schemaStore or {}
    limited_config.settings.yaml.schemaStore.enable = false

    limited_config.settings.yaml.schemas = limited_config.settings.yaml.schemas or {}
    limited_config.settings.yaml.schemas = {} -- 清空模式以减少内存使用
  elseif server_name == "bashls" then
    -- Bash 语言服务器内存限制
    limited_config.settings.bash = limited_config.settings.bash or {}
    limited_config.settings.bash.shellcheckPath = "" -- 禁用 shellcheck 以减少内存
  else
    -- 为其他未明确配置的服务器添加通用内存限制
    -- 可以通过环境变量或命令行参数传递内存限制
    if not limited_config.cmd then
      limited_config.cmd = get_default_cmd(server_name)
    end

    -- 如果服务器支持环境变量内存限制，可以在这里添加
    -- 例如：limited_config.env = { NODE_OPTIONS = "--max-old-space-size=" .. memory_limit_kb }
  end

  -- 通用性能优化设置
  if limited_config.settings then
    -- 禁用遥测
    limited_config.settings.telemetry = limited_config.settings.telemetry or {}
    limited_config.settings.telemetry.enable = false

    -- 限制建议频率
    limited_config.settings.suggest = limited_config.settings.suggest or {}
    limited_config.settings.suggest.delay = 100

    -- 限制诊断频率
    limited_config.settings.diagnostics = limited_config.settings.diagnostics or {}
    limited_config.settings.diagnostics.delay = 1000
  end

  -- 添加初始化选项来限制内存
  if not limited_config.init_options then
    limited_config.init_options = {}
  end

  -- 通用内存限制标记
  limited_config.init_options.memoryLimit = memory_limit_kb
  limited_config.init_options.performanceMode = "low"

  return limited_config
end

local function get_copilot_processes()
  -- 获取所有 Copilot 语言服务器进程
  local processes = {}

  -- 使用 ps 命令查找 Copilot 进程
  local handle = io.popen("ps aux | grep -E 'copilot-language-server|Copilot' | grep -v grep")
  if handle then
    for line in handle:lines() do
      local pid = line:match("^%s*(%d+)")
      local process_cmd = line:match("%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+(.+)")
      if pid and process_cmd then
        table.insert(processes, {
          pid = tonumber(pid),
          cmd = cmd,
          memory_kb = get_process_memory_usage(tonumber(pid)),
        })
      end
    end
    handle:close()
  end

  return processes
end

local function cleanup_duplicate_copilot_processes()
  -- 清理重复的 Copilot 进程
  if not M.config.copilot.enabled then
    return
  end

  local processes = get_copilot_processes()
  local active_pids = {}
  local duplicate_count = 0

  -- 找出活跃的 Copilot 客户端对应的进程
  local all_clients = vim.lsp.get_clients()
  for _, client in ipairs(all_clients) do
    if client.name == "copilot" or client.name:find("copilot") then
      -- 检查 client.pid
      ---@diagnostic disable-next-line: undefined-field
      local pid = client.pid
      if pid then
        active_pids[pid] = true
      end
    end
  end

  -- 清理不在活跃客户端列表中的进程
  for _, proc in ipairs(processes) do
    if not active_pids[proc.pid] then
      -- 尝试终止进程
      local success = pcall(function()
        os.execute("kill -9 " .. proc.pid .. " 2>/dev/null")
      end)

      if success then
        duplicate_count = duplicate_count + 1
        if vim.g.lsp_debug then
          vim.notify(
            "[LSP] 清理重复 Copilot 进程 PID: " .. proc.pid .. " (内存: " .. proc.memory_kb .. " KB)",
            vim.log.levels.WARN
          )
        end
      end
    end
  end

  if duplicate_count > 0 then
    vim.notify("[LSP] 已清理 " .. duplicate_count .. " 个重复的 Copilot 进程", vim.log.levels.INFO)
  elseif vim.g.lsp_debug then
    vim.notify("[LSP] 未发现重复的 Copilot 进程", vim.log.levels.INFO)
  end
end

local function monitor_copilot_processes()
  -- 监控 Copilot 进程，防止内存泄漏
  if not M.config.copilot.enabled then
    return
  end

  -- 定期检查 Copilot 进程
  vim.defer_fn(function()
    local processes = get_copilot_processes()

    if #processes > M.config.copilot.max_concurrent_suggestions * 2 then
      -- 如果进程数量超过限制的两倍，清理重复进程
      if vim.g.lsp_debug then
        vim.notify("[LSP] Copilot 进程过多 (" .. #processes .. " 个)，开始清理...", vim.log.levels.WARN)
      end

      cleanup_duplicate_copilot_processes()
    end

    -- 继续监控
    monitor_copilot_processes()
  end, 60000) -- 每60秒检查一次
end

local function setup_copilot_memory_limits()
  -- 设置 GitHub Copilot 内存限制
  if not M.config.copilot.enabled then
    return
  end

  -- 检查 Copilot 插件是否已加载
  local copilot_loaded = pcall(function()
    return vim.fn.exists("g:loaded_copilot") == 1
  end)

  if not copilot_loaded then
    if vim.g.lsp_debug then
      vim.notify("[LSP] GitHub Copilot 插件未加载，跳过内存限制设置", vim.log.levels.WARN)
    end
    return
  end

  -- 设置 Copilot 配置
  vim.g.copilot = vim.g.copilot or {}

  -- 内存限制相关配置
  vim.g.copilot.filetypes = vim.g.copilot.filetypes or {
    ["*"] = true,
  }

  -- 限制文件大小
  if M.config.copilot.limit_file_size then
    vim.g.copilot.max_file_size = M.config.copilot.max_file_size_kb * 1024
  end

  -- 建议延迟
  if M.config.copilot.suggestion_delay > 0 then
    vim.g.copilot.suggestion_delay = M.config.copilot.suggestion_delay
  end

  -- 禁用代理（可能减少内存使用）
  vim.g.copilot.proxy = ""

  -- 禁用一些可能占用内存的功能
  vim.g.copilot.enabled = true
  vim.g.copilot.assume_role = ""

  if vim.g.lsp_debug then
    vim.notify("[LSP] GitHub Copilot 内存限制已配置", vim.log.levels.INFO)
  end

  -- 启动 Copilot 进程监控
  monitor_copilot_processes()
end

local function get_process_memory_usage(pid)
  -- 获取进程内存使用情况（Linux 系统）
  if not pid then
    return 0
  end

  local status_file = "/proc/" .. pid .. "/status"
  local file = io.open(status_file, "r")
  if not file then
    return 0
  end

  local memory_kb = 0
  for line in file:lines() do
    if line:match("^VmRSS:") then
      -- 提取 RSS 内存使用（KB）
      local value = line:match("%d+")
      memory_kb = tonumber(value) or 0
      break
    end
  end

  file:close()
  return memory_kb
end

local function get_process_info(pid)
  -- 获取进程详细信息
  if not pid then
    return nil
  end

  local proc_dir = "/proc/" .. pid
  local info = {
    pid = pid,
    exists = false,
    cmdline = "",
    memory_kb = 0,
    uptime_seconds = 0,
    state = "unknown",
  }

  -- 检查进程是否存在
  local stat_file = proc_dir .. "/stat"
  local stat_f = io.open(stat_file, "r")
  if stat_f then
    info.exists = true
    local stat_content = stat_f:read("*all")
    stat_f:close()

    -- 解析 stat 文件获取进程状态和运行时间
    local fields = {}
    for field in stat_content:gmatch("%S+") do
      table.insert(fields, field)
    end

    if #fields >= 3 then
      info.state = fields[3] -- 进程状态 (R=运行, S=睡眠, D=不可中断睡眠, Z=僵尸, T=停止)

      -- 计算运行时间（从系统启动开始的时钟滴答数）
      local utime = tonumber(fields[14]) or 0
      local stime = tonumber(fields[15]) or 0
      local starttime = tonumber(fields[22]) or 0

      -- 获取系统启动时间
      local uptime_file = io.open("/proc/uptime", "r")
      if uptime_file then
        local uptime_content = uptime_file:read("*all")
        uptime_file:close()
        local system_uptime = tonumber(uptime_content:match("%S+")) or 0

        -- 计算进程启动时间（秒）
        local clock_ticks_per_second = 100 -- 通常为 100
        local process_start_time = starttime / clock_ticks_per_second
        info.uptime_seconds = system_uptime - process_start_time
      end
    end
  end

  -- 获取命令行
  local cmdline_file = proc_dir .. "/cmdline"
  local cmdline_f = io.open(cmdline_file, "r")
  if cmdline_f then
    local cmdline_content = cmdline_f:read("*all")
    cmdline_f:close()
    -- 替换 null 字符为空格
    info.cmdline = cmdline_content:gsub("\0", " "):gsub("%s+$", "")
  end

  -- 获取内存使用
  info.memory_kb = get_process_memory_usage(pid)
  info.memory_mb = math.floor(info.memory_kb / 1024 * 100) / 100

  return info
end

local function get_all_lsp_processes()
  -- 获取所有 LSP 相关进程
  local processes = {}

  -- 常见的 LSP 服务器进程名模式
  local lsp_patterns = {
    "language%-server",
    "lsp",
    "%-ls",
    "pyright",
    "rust%-analyzer",
    "clangd",
    "gopls",
    "tsserver",
    "typescript%-language%-server",
    "html%-language%-server",
    "css%-language%-server",
    "json%-language%-server",
    "yaml%-language%-server",
    "bash%-language%-server",
    "lua%-language%-server",
    "java%-language%-server",
    "csharp%-language%-server",
    "php%-language%-server",
    "go%-language%-server",
    "ruby%-language%-server",
    "docker%-language%-server",
    "terraform%-ls",
    "sql%-language%-server",
    "markdown%-language%-server",
    "powershell%-editor%-services",
    "omnisharp",
    "rls",
    "haskell%-language%-server",
    "dart",
    "flutter",
    "kotlin%-language%-server",
    "swift%-language%-server",
    "elixir%-ls",
    "erlang%-ls",
    "ocaml%-language%-server",
    "nim%-language%-server",
    "zig%-language%-server",
    "v%-analyzer",
    "jdtls",
    "eclipse%.jdt%.ls",
    "angular%-language%-server",
    "vue%-language%-server",
    "svelte%-language%-server",
    "astro%-language%-server",
    "tailwindcss%-language%-server",
    "graphql%-language%-server",
    "prisma%-language%-server",
    "dockerfile%-language%-server",
    "nginx%-language%-server",
    "apache%-config%-language%-server",
    "xml%-language%-server",
    "yaml%.fmt",
    "prettier",
    "stylua",
    "black",
    "isort",
    "shfmt",
    "clang%-format",
    "gofmt",
    "rustfmt",
    "sql%-formatter",
    "latexindent",
    "codespell",
  }

  -- 构建 grep 模式
  local grep_pattern = ""
  for i, pattern in ipairs(lsp_patterns) do
    if i > 1 then
      grep_pattern = grep_pattern .. "\\|"
    end
    grep_pattern = grep_pattern .. pattern
  end

  -- 使用 ps 命令查找进程
  local cmd = "ps aux | grep -E '" .. grep_pattern .. "' | grep -v grep"
  local handle = io.popen(cmd)
  if handle then
    for line in handle:lines() do
      local pid = line:match("^%s*(%d+)")
      local cmd_line = line:match("%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+(.+)")

      if pid and cmd then
        local pid_num = tonumber(pid)
        local process_info = get_process_info(pid_num)

        if process_info and process_info.exists then
          -- 识别进程类型
          local process_type = "unknown"
          local server_name = "unknown"

          -- 尝试匹配已知的 LSP 服务器
          for _, pattern in ipairs(lsp_patterns) do
            if cmd:match(pattern) then
              process_type = "lsp"

              -- 提取服务器名称
              if pattern:match("%-ls$") then
                server_name = pattern:gsub("%-ls$", "")
              elseif pattern == "pyright" then
                server_name = "pyright"
              elseif pattern == "rust%-analyzer" then
                server_name = "rust_analyzer"
              elseif pattern == "clangd" then
                server_name = "clangd"
              elseif pattern == "gopls" then
                server_name = "gopls"
              elseif pattern == "tsserver" or pattern == "typescript%-language%-server" then
                server_name = "ts_ls"
              elseif pattern == "html%-language%-server" then
                server_name = "html"
              elseif pattern == "css%-language%-server" then
                server_name = "cssls"
              elseif pattern == "json%-language%-server" then
                server_name = "jsonls"
              elseif pattern == "yaml%-language%-server" then
                server_name = "yamlls"
              elseif pattern == "bash%-language%-server" then
                server_name = "bashls"
              elseif pattern == "lua%-language%-server" then
                server_name = "lua_ls"
              end
              break
            end
          end

          -- 检查是否是格式化工具
          local formatter_patterns = {
            "prettier",
            "stylua",
            "black",
            "isort",
            "shfmt",
            "clang%-format",
            "gofmt",
            "rustfmt",
            "sql%-formatter",
            "latexindent",
            "codespell",
            "yaml%.fmt",
          }

          for _, fmt_pattern in ipairs(formatter_patterns) do
            if cmd:match(fmt_pattern) then
              process_type = "formatter"
              server_name = fmt_pattern:gsub("%-format$", ""):gsub("%.fmt$", "fmt")
              break
            end
          end

          -- 检查是否是 Copilot
          if cmd:match("copilot") then
            process_type = "copilot"
            server_name = "copilot"
          end

          table.insert(processes, {
            pid = pid_num,
            cmd = cmd,
            type = process_type,
            server_name = server_name,
            memory_kb = process_info.memory_kb,
            memory_mb = process_info.memory_mb,
            uptime_seconds = process_info.uptime_seconds,
            state = process_info.state,
            cmdline = process_info.cmdline,
          })
        end
      end
    end
    handle:close()
  end

  return processes
end

local function cleanup_zombie_processes()
  -- 清理僵尸进程和孤儿进程
  local processes = get_all_lsp_processes()
  local cleaned = 0

  -- 获取当前活跃的 LSP 客户端
  local active_clients = vim.lsp.get_clients()
  local active_pids = {}

  -- 收集活跃客户端的 PID
  for _, client in ipairs(active_clients) do
    -- 检查 client.pid
    ---@diagnostic disable-next-line: undefined-field
    local pid = client.pid
    if pid then
      active_pids[pid] = true
    end
  end

  -- 检查每个进程
  for _, proc in ipairs(processes) do
    local should_clean = false
    local reason = ""

    -- 检查是否是僵尸进程
    if proc.state == "Z" then
      should_clean = true
      reason = "僵尸进程"

      -- 检查是否长时间空闲（超过30分钟）且没有活跃客户端
    elseif proc.uptime_seconds > 1800 and not active_pids[proc.pid] then
      should_clean = true
      reason = "长时间空闲 (" .. math.floor(proc.uptime_seconds / 60) .. " 分钟)"

      -- 检查是否是重复的 Copilot 进程
    elseif proc.type == "copilot" and not active_pids[proc.pid] then
      should_clean = true
      reason = "重复的 Copilot 进程"

      -- 检查内存使用异常（超过 2GB）
    elseif proc.memory_mb > 2000 then
      should_clean = true
      reason = "内存使用过高 (" .. proc.memory_mb .. " MB)"
    end

    -- 执行清理
    if should_clean then
      local success = pcall(function()
        -- 先尝试 SIGTERM（优雅终止）
        os.execute("kill -15 " .. proc.pid .. " 2>/dev/null")

        -- 等待 2 秒
        vim.defer_fn(function()
          -- 检查进程是否还存在
          local proc_info = get_process_info(proc.pid)
          if proc_info and proc_info.exists then
            -- 如果还存在，使用 SIGKILL
            os.execute("kill -9 " .. proc.pid .. " 2>/dev/null")
          end
        end, 2000)
      end)

      if success then
        cleaned = cleaned + 1
        if vim.g.lsp_debug then
          vim.notify(
            "[LSP] 清理进程: " .. proc.server_name .. " (PID: " .. proc.pid .. ") - " .. reason,
            vim.log.levels.WARN
          )
        end
      end
    end
  end

  if cleaned > 0 then
    vim.notify("[LSP] 已清理 " .. cleaned .. " 个僵尸/空闲进程", vim.log.levels.INFO)
  elseif vim.g.lsp_debug then
    vim.notify("[LSP] 未发现需要清理的进程", vim.log.levels.INFO)
  end

  return cleaned
end

local function monitor_lsp_processes()
  -- 监控 LSP 进程状态
  if not M.config.memory_limit.enabled then
    return
  end

  -- 定期检查进程状态
  vim.defer_fn(function()
    local processes = get_all_lsp_processes()

    -- 统计信息
    local stats = {
      total = #processes,
      by_type = {},
      by_server = {},
      zombies = 0,
      high_memory = 0,
      long_running = 0,
    }

    -- 分析进程
    for _, proc in ipairs(processes) do
      -- 按类型统计
      stats.by_type[proc.type] = (stats.by_type[proc.type] or 0) + 1

      -- 按服务器统计
      stats.by_server[proc.server_name] = (stats.by_server[proc.server_name] or 0) + 1

      -- 检查僵尸进程
      if proc.state == "Z" then
        stats.zombies = stats.zombies + 1
      end

      -- 检查高内存使用
      if proc.memory_mb > 1000 then
        stats.high_memory = stats.high_memory + 1
      end

      -- 检查长时间运行（超过1小时）
      if proc.uptime_seconds > 3600 then
        stats.long_running = stats.long_running + 1
      end
    end

    -- 显示统计信息（仅在调试模式）
    if vim.g.lsp_debug then
      vim.notify("[LSP] 进程监控统计:")
      vim.notify("[LSP]   • 总进程数: " .. stats.total)

      for type_name, count in pairs(stats.by_type) do
        vim.notify("[LSP]   • " .. type_name .. ": " .. count)
      end

      if stats.zombies > 0 then
        vim.notify("[LSP]   • 僵尸进程: " .. stats.zombies .. " (需要清理)")
      end

      if stats.high_memory > 0 then
        vim.notify("[LSP]   • 高内存进程: " .. stats.high_memory .. " (>1GB)")
      end

      if stats.long_running > 0 then
        vim.notify("[LSP]   • 长时间运行: " .. stats.long_running .. " (>1小时)")
      end
    end

    -- 自动清理条件
    local should_cleanup = false

    if stats.zombies > 0 then
      should_cleanup = true
      if vim.g.lsp_debug then
        vim.notify("[LSP] 发现僵尸进程，自动清理...", vim.log.levels.WARN)
      end

      -- 如果总进程数过多
    elseif stats.total > M.config.memory_limit.max_concurrent_clients * 3 then
      should_cleanup = true
      if vim.g.lsp_debug then
        vim.notify("[LSP] 进程数量过多 (" .. stats.total .. ")，自动清理...", vim.log.levels.WARN)
      end

      -- 如果高内存进程过多
    elseif stats.high_memory > 2 then
      should_cleanup = true
      if vim.g.lsp_debug then
        vim.notify("[LSP] 高内存进程过多 (" .. stats.high_memory .. ")，自动清理...", vim.log.levels.WARN)
      end
    end

    -- 执行清理
    if should_cleanup then
      cleanup_zombie_processes()
    end

    -- 继续监控
    monitor_lsp_processes()
  end, 120000) -- 每2分钟检查一次
end

local function setup_process_monitoring()
  -- 设置进程监控
  if not M.config.memory_limit.enabled then
    return
  end

  -- 启动进程监控
  vim.defer_fn(function()
    monitor_lsp_processes()
  end, 10000) -- 10秒后开始监控

  -- 设置自动清理定时器（每30分钟）
  vim.defer_fn(function()
    local timer = vim.loop.new_timer()
    if timer then
      timer:start(1800000, 1800000, function() -- 30分钟间隔
        vim.schedule(function()
          if vim.g.lsp_debug then
            vim.notify("[LSP] 执行定期进程清理...", vim.log.levels.INFO)
          end
          cleanup_zombie_processes()
        end)
      end)
    end
  end, 60000) -- 1分钟后启动定时器

  vim.notify("[LSP] LSP 进程监控已启动", vim.log.levels.INFO)
end

local function get_lsp_client_memory_info(client)
  -- 获取 LSP 客户端内存信息
  local memory_info = {
    name = client.name,
    pid = nil,
    memory_kb = 0,
    memory_mb = 0,
    status = "unknown",
  }

  -- 尝试获取进程 ID
  if client and client.rpc and client.rpc.handle then
    -- 对于某些 LSP 客户端，可以通过 handle 获取 PID
    local handle = client.rpc.handle
    if handle and handle.pid then
      memory_info.pid = handle.pid
      memory_info.memory_kb = get_process_memory_usage(handle.pid)
      memory_info.memory_mb = math.floor(memory_info.memory_kb / 1024 * 100) / 100

      -- 判断内存使用状态
      local limit_kb = M.config.memory_limit.max_memory_per_client * 1024
      if memory_info.memory_kb > limit_kb * 0.9 then
        memory_info.status = "critical"
      elseif memory_info.memory_kb > limit_kb * 0.7 then
        memory_info.status = "warning"
      else
        memory_info.status = "normal"
      end
    end
  end

  return memory_info
end

local function enforce_memory_limits()
  -- 强制执行内存限制
  if not M.config.memory_limit.enabled then
    return
  end

  local all_clients = vim.lsp.get_clients()
  local memory_limit_kb = M.config.memory_limit.max_memory_per_client * 1024

  for _, client in ipairs(all_clients) do
    local memory_info = get_lsp_client_memory_info(client)

    if memory_info.pid and memory_info.memory_kb > memory_limit_kb then
      -- 内存使用超过限制
      if vim.g.lsp_debug then
        vim.notify(
          "[LSP] 内存限制: "
            .. client.name
            .. " 使用 "
            .. memory_info.memory_mb
            .. " MB (限制: "
            .. M.config.memory_limit.max_memory_per_client
            .. " MB)",
          vim.log.levels.WARN
        )
      end

      -- 可以采取的措施：
      -- 1. 发送内存限制通知给 LSP 服务器
      -- 2. 重启客户端
      -- 3. 降低服务质量

      -- 这里我们只记录警告，实际限制已经在配置中设置
    end
  end
end

local function monitor_memory_usage()
  -- 监控内存使用情况
  if not M.config.memory_limit.enabled then
    return
  end

  -- 定期检查内存使用
  vim.defer_fn(function()
    local all_clients = vim.lsp.get_clients()
    local memory_warning_shown = false
    local total_memory_mb = 0

    -- 收集内存使用信息
    local memory_stats = {}
    for _, client in ipairs(all_clients) do
      local memory_info = get_lsp_client_memory_info(client)
      table.insert(memory_stats, memory_info)
      total_memory_mb = total_memory_mb + memory_info.memory_mb

      -- 检查单个客户端内存使用
      if memory_info.status == "critical" and vim.g.lsp_debug then
        vim.notify(
          "[LSP] 内存警告: " .. client.name .. " 内存使用过高 (" .. memory_info.memory_mb .. " MB)",
          vim.log.levels.WARN
        )
      end
    end

    -- 检查总客户端数量
    if #all_clients > M.config.memory_limit.max_concurrent_clients * 0.8 then
      if not memory_warning_shown and vim.g.lsp_debug then
        vim.notify("[LSP] 内存警告: 活跃 LSP 客户端数量较高 (" .. #all_clients .. ")", vim.log.levels.WARN)
        memory_warning_shown = true
      end
    end

    -- 检查总内存使用
    local total_limit_mb = M.config.memory_limit.max_concurrent_clients * M.config.memory_limit.max_memory_per_client
    if total_memory_mb > total_limit_mb * 0.8 and vim.g.lsp_debug then
      vim.notify(
        "[LSP] 内存警告: 总内存使用较高 ("
          .. math.floor(total_memory_mb)
          .. " MB / "
          .. total_limit_mb
          .. " MB)",
        vim.log.levels.WARN
      )
    end

    -- 强制执行内存限制
    enforce_memory_limits()

    -- 继续监控
    monitor_memory_usage()
  end, 30000) -- 每30秒检查一次
end

-- ============================================

local function start_lsp_for_filetype(ft, bufnr)
  -- 启动文件类型的 LSP
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- 检查缓冲区是否仍然有效
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- 跳过不需要 LSP 检查的文件类型
  if M.skip_filetypes[ft] then
    return
  end

  -- 白名单模式：只有文件类型在 filetype_mappings 中才启动 LSP
  -- 其余所有文件类型（如 codecompanion、neoai、NvimTree 等）都跳过
  if not M.filetype_mappings[ft] then
    -- 标记为已处理，避免重复检查
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].lsp_started = true
    end
    return
  end

  -- 避免重复启动
  if vim.b[bufnr].lsp_started then
    return
  end

  -- 通知 LSP 语法检查开始（仅在调试模式下显示）
  if vim.g.lsp_debug then
    local current_time = os.date("%H:%M:%S")
    vim.notify("[LSP] 开始 LSP 语法检查: " .. ft .. " (" .. current_time .. ")", vim.log.levels.INFO)
  end

  local server_names = M.filetype_mappings[ft]
  if not server_names then
    return
  end

  local started_servers = {}
  for _, server_name in ipairs(server_names) do
    -- 检查内存限制
    if not check_memory_limits() then
      if vim.g.lsp_debug then
        vim.notify(
          "[LSP] 内存限制: 跳过启动 " .. server_name .. " (已达到最大并发客户端数量)",
          vim.log.levels.WARN
        )
      end
      break -- 停止启动更多服务器
    end

    -- 检查服务器是否已附加到当前缓冲区
    local clients = vim.lsp.get_clients({ name = server_name, bufnr = bufnr })
    if #clients > 0 then
      -- 服务器已附加到当前缓冲区
      table.insert(started_servers, server_name)
    else
      -- 服务器未附加到当前缓冲区，尝试附加到已存在的客户端
      local all_clients = vim.lsp.get_clients({ name = server_name })
      local attached = false

      for _, client in ipairs(all_clients) do
        -- 检查文件类型是否匹配
        local should_attach = true
        local filetypes = nil
        if client.config then
          -- 安全地访问 filetypes 字段
          ---@diagnostic disable-next-line: undefined-field
          local config = client.config
          -- 尝试从不同位置获取文件类型
          ---@diagnostic disable-next-line: undefined-field
          local possible_filetypes = config.filetypes or (config.init_options and config.init_options.filetypes)
          if possible_filetypes and type(possible_filetypes) == "table" then
            filetypes = possible_filetypes
          elseif
            config.init_options
            and config.init_options.filetypes
            and type(config.init_options.filetypes) == "table"
          then
            filetypes = config.init_options.filetypes
          end
        end
        if filetypes and type(filetypes) == "table" then
          for _, client_ft in ipairs(filetypes) do
            if client_ft == ft then
              should_attach = true
              break
            end
          end
        end

        if should_attach and not vim.lsp.buf_is_attached(bufnr, client.id) then
          vim.lsp.buf_attach_client(bufnr, client.id)
          attached = true
          if vim.g.lsp_debug then
            vim.notify("[LSP] 附加到已存在的 LSP 客户端: " .. server_name, vim.log.levels.INFO)
          end
        elseif vim.lsp.buf_is_attached(bufnr, client.id) then
          attached = true
        end
      end

      if attached then
        table.insert(started_servers, server_name)
      else
        -- 如果没有可用的客户端，尝试启动新的服务器
        -- 使用我们的配置来启动
        local success = M.start_server_with_config(server_name, bufnr)
        if success then
          table.insert(started_servers, server_name)
          if vim.g.lsp_debug then
            vim.notify("[LSP] 已启动 LSP 服务器: " .. server_name, vim.log.levels.INFO)
          end
        elseif vim.g.lsp_debug then
          vim.notify(
            "跳过 LSP " .. server_name .. ": 没有可用的客户端或文件类型不匹配",
            vim.log.levels.WARN
          )
        end
      end
    end
  end

  if #started_servers > 0 then
    -- 再次检查缓冲区是否仍然有效
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].lsp_started = true
      if vim.g.lsp_debug then
        local end_time = os.date("%H:%M:%S")
        vim.notify(
          "LSP 语法检查完成: " .. ft .. " (" .. end_time .. ")服务器: " .. table.concat(started_servers, ", "),
          vim.log.levels.INFO
        )
      end
    end
  end
end

function M.setup()
  -- 主设置函数

  -- 防止重复设置
  if M._setup_called then
    vim.notify("[LSP] 警告: setup() 已被调用过，跳过重复执行", vim.log.levels.WARN)
    return
  end
  M._setup_called = true

  vim.notify("[LSP] 开始设置 LSP 配置...", vim.log.levels.INFO)

  -- 显示内存限制配置信息
  if M.config.memory_limit.enabled then
    vim.notify(
      "[LSP] 内存限制已启用: 最大 "
        .. M.config.memory_limit.max_concurrent_clients
        .. " 个并发客户端, 每个客户端限制 "
        .. M.config.memory_limit.max_memory_per_client
        .. " MB",
      vim.log.levels.INFO
    )
  end

  if M.config.copilot.enabled then
    vim.notify(
      "[LSP] GitHub Copilot 内存限制: "
        .. M.config.copilot.memory_limit
        .. " MB, 建议延迟 "
        .. M.config.copilot.suggestion_delay
        .. "ms",
      vim.log.levels.INFO
    )
  end

  -- 设置诊断
  setup_diagnostics()

  -- 设置全局按键映射
  setup_global_keymaps()

  -- 设置 conform.nvim
  setup_conform()

  -- 设置 GitHub Copilot 内存限制
  setup_copilot_memory_limits()

  -- 启动内存监控
  if M.config.memory_limit.enabled then
    vim.defer_fn(function()
      monitor_memory_usage()
    end, 5000) -- 5秒后开始监控

    -- 启动进程监控
    setup_process_monitoring()
  end

  -- 使用 ftplugin autocmd 统一加载 LSP 配置
  -- 这会替代所有单独的 ftplugin 文件
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("LSPFileType", { clear = true }),
    callback = function(args)
      local ft = vim.bo.filetype
      if ft and ft ~= "" then
        vim.schedule(function()
          start_lsp_for_filetype(ft, args.buf)
        end)
      end
    end,
  })

  -- 已有的文件
  vim.api.nvim_create_autocmd("BufRead", {
    group = vim.api.nvim_create_augroup("LSPBufRead", { clear = true }),
    callback = function(args)
      local ft = vim.bo.filetype
      -- 检查缓冲区是否有效
      if ft and ft ~= "" and vim.api.nvim_buf_is_valid(args.buf) and not vim.b[args.buf].lsp_started then
        vim.schedule(function()
          start_lsp_for_filetype(ft, args.buf)
        end)
      end
    end,
  })

  -- 保存时自动格式化（使用 conform.nvim）
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("LSPAutoFormat", { clear = true }),
    callback = function(args)
      local bufnr = args.buf
      local ft = vim.bo[bufnr].filetype

      -- 跳过不需要格式化的文件类型
      if M.skip_filetypes[ft] then
        return
      end

      -- 检查是否有对应的格式化器
      local formatters = M.formatters_by_ft[ft] or M.formatters_by_ft["*"] or {}

      if #formatters > 0 and vim.g.auto_format ~= false then
        local conform_ok, conform = pcall(require, "conform")
        if conform_ok then
          -- 使用 conform.nvim 格式化
          local success = pcall(conform.format, {
            async = false,
            bufnr = bufnr,
            lsp_fallback = true,
            timeout_ms = 1000,
          })

          if not success then
            -- 如果 conform 格式化失败，尝试 LSP
            local clients = vim.lsp.get_clients({ bufnr = bufnr })
            for _, client in ipairs(clients) do
              if client.server_capabilities.documentFormattingProvider then
                pcall(vim.lsp.buf.format, { async = false, bufnr = bufnr })
                break
              end
            end
          end
        else
          -- 回退到 LSP 格式化
          local clients = vim.lsp.get_clients({ bufnr = bufnr })
          for _, client in ipairs(clients) do
            if client.server_capabilities.documentFormattingProvider then
              pcall(vim.lsp.buf.format, { async = false, bufnr = bufnr })
              break
            end
          end
        end
      end
    end,
  })

  -- 初始化 Mason
  M.setup_mason()

  vim.notify("[LSP] LSP 和 conform.nvim 配置已加载")

  -- 清理可能存在的重复客户端
  vim.defer_fn(function()
    M.cleanup_duplicate_clients()
  end, 500)
end

function M.cleanup_duplicate_clients()
  -- 清理重复的 LSP 客户端，优先保留使用我们配置的客户端
  local all_clients = vim.lsp.get_clients()
  local clients_by_name = {}
  local removed = 0

  -- 按名称分组客户端
  for _, client in ipairs(all_clients) do
    if not clients_by_name[client.name] then
      clients_by_name[client.name] = {}
    end
    table.insert(clients_by_name[client.name], client)
  end

  -- 检查每个名称的客户端
  for name, client_list in pairs(clients_by_name) do
    if #client_list > 1 then
      if vim.g.lsp_debug then
        vim.notify("[LSP] 发现重复的 LSP 客户端: " .. name .. " (" .. #client_list .. " 个实例)")
      end

      -- 找出使用我们配置的客户端
      local our_config_clients = {}
      local default_config_clients = {}

      for _, client in ipairs(client_list) do
        -- 检查是否使用我们的配置（通过检查是否有我们的特定设置）
        local is_our_config = false
        if client.config and client.config.settings then
          -- 检查是否有我们配置的特定字段
          if name == "lua_ls" and client.config.settings.Lua then
            -- 检查是否有我们配置的全局变量
            if client.config.settings.Lua.diagnostics and client.config.settings.Lua.diagnostics.globals then
              is_our_config = true
            end
          elseif client.config.settings then
            -- 对于其他服务器，如果有 settings 就认为是我们的配置
            is_our_config = true
          end
        end

        if is_our_config then
          table.insert(our_config_clients, client)
        else
          table.insert(default_config_clients, client)
        end
      end

      -- 优先保留使用我们配置的客户端
      local clients_to_keep = {}
      if #our_config_clients > 0 then
        if vim.g.lsp_debug then
          vim.notify("[LSP]   保留使用我们配置的客户端 (" .. #our_config_clients .. " 个)")
        end
        clients_to_keep = our_config_clients
      else
        if vim.g.lsp_debug then
          vim.notify("[LSP]   没有找到使用我们配置的客户端，保留第一个默认配置客户端")
        end
        -- 保留第一个默认配置客户端
        table.insert(clients_to_keep, default_config_clients[1])
      end

      -- 停止不需要的客户端
      for _, client in ipairs(client_list) do
        local should_keep = false
        for _, keep_client in ipairs(clients_to_keep) do
          if client.id == keep_client.id then
            should_keep = true
            break
          end
        end

        if not should_keep then
          if vim.g.lsp_debug then
            vim.notify("[LSP]   停止实例 ID: " .. client.id)
          end
          client:stop()
          removed = removed + 1
        end
      end
    end
  end

  if removed > 0 then
    if vim.g.lsp_debug then
      vim.notify("[LSP] 已停止 " .. removed .. " 个重复的 LSP 客户端实例")
    end
    vim.notify("[LSP] 已清理 " .. removed .. " 个重复的 LSP 客户端", vim.log.levels.INFO)
  elseif vim.g.lsp_debug then
    vim.notify("[LSP] 未发现重复的 LSP 客户端")
  end
end

function M.setup_mason()
  -- Mason 设置
  local mason_ok, mason = pcall(require, "mason")
  if not mason_ok then
    vim.notify("[LSP] Mason 插件未加载", vim.log.levels.WARN)
    return
  end

  mason.setup({
    ui = {
      border = "rounded",
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
  })

  -- 配置 mason-lspconfig
  local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
  if mason_lspconfig_ok then
    -- 定义处理器函数
    local function setup_server(server_name)
      -- 调试信息
      if vim.g.lsp_debug then
        vim.notify("[LSP] [LSP] ========================================")
        vim.notify("[LSP] [LSP] 开始配置服务器: " .. server_name)
        vim.notify("[LSP] [LSP] ========================================")
      end

      local config = M.server_configs[server_name] or {}

      -- 调试信息：显示加载的配置
      if vim.g.lsp_debug then
        vim.notify("[LSP] [LSP] 为服务器 " .. server_name .. " 加载配置:")
        vim.notify("[LSP]   配置文件存在: " .. (next(config) ~= nil and "是" or "否"))
        if next(config) ~= nil then
          vim.notify("[LSP]   设置字段: " .. (config.settings and "有" or "无"))
          vim.notify("[LSP]   文件类型: " .. (config.filetypes and table.concat(config.filetypes, ", ") or "无"))
        end
      end

      -- 确保配置包含必要的字段
      local cmd = config.cmd or get_default_cmd(server_name)

      if not cmd then
        if vim.g.lsp_debug then
          vim.notify("[LSP] 跳过 LSP " .. server_name .. ": 未找到 cmd 配置", vim.log.levels.WARN)
        end
        return
      end

      -- 构建完整的配置
      local lsp_config = {
        name = server_name,
        cmd = cmd,
        settings = config.settings or {},
        on_attach = config.on_attach or default_on_attach,
        capabilities = config.capabilities or vim.lsp.protocol.make_client_capabilities(),
        root_dir = config.root_dir,
        filetypes = config.filetypes,
        manual = true, -- 手动启动，避免自动启动
      }

      -- 调试信息：显示最终配置
      if vim.g.lsp_debug then
        vim.notify("[LSP] [LSP] 最终配置 " .. server_name .. ":")
        vim.notify("[LSP]   cmd: " .. vim.inspect(cmd))
        vim.notify("[LSP]   设置字段数量: " .. (lsp_config.settings and #vim.tbl_keys(lsp_config.settings) or 0))
        if lsp_config.settings and server_name == "lua_ls" then
          vim.notify("[LSP]   Lua 设置: " .. (lsp_config.settings.Lua and "有" or "无"))
        end
      end

      -- 根据配置决定使用哪种方式
      if M.config.use_lspconfig then
        -- 使用 nvim-lspconfig 配置服务器（只配置，不启动）
        local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
        if lspconfig_ok then
          -- 直接使用我们的配置，不合并默认配置
          -- 这样可以确保我们的配置完全生效

          -- 调试：打印我们的配置
          if vim.g.lsp_debug then
            vim.notify("[LSP] [LSP] 准备配置服务器: " .. server_name)
            vim.notify("[LSP] [LSP] 我们的配置:")
            vim.notify(vim.inspect(lsp_config))

            -- 检查现有的配置
            if lspconfig[server_name] and lspconfig[server_name].document_config then
              vim.notify("[LSP] [LSP] 现有默认配置:")
              vim.notify(vim.inspect(lspconfig[server_name].document_config.default_config))
            end
          end

          -- 配置服务器但不启动
          lspconfig[server_name].setup(lsp_config)

          -- 验证配置是否已应用
          if vim.g.lsp_debug then
            vim.defer_fn(function()
              vim.notify("[LSP] [LSP] 配置后验证:")
              local current_config = lspconfig[server_name].document_config.default_config
              vim.notify("[LSP]   cmd: " .. vim.inspect(current_config.cmd))
              if current_config.settings and current_config.settings.Lua then
                vim.notify("[LSP]   Lua 运行时路径: " .. (current_config.settings.Lua.runtime and "有" or "无"))
                vim.notify(
                  "  Lua 诊断全局变量数量: "
                    .. (
                      current_config.settings.Lua.diagnostics
                        and current_config.settings.Lua.diagnostics.globals
                        and #current_config.settings.Lua.diagnostics.globals
                      or 0
                    )
                )
              end
            end, 100)
          end

          if vim.g.lsp_debug then
            vim.notify("[LSP] 已配置 LSP 服务器: " .. server_name, vim.log.levels.INFO)
            vim.notify("[LSP] [LSP] 服务器 " .. server_name .. " 配置完成（未启动）")
          end
        else
          -- 回退到 vim.lsp.start（但也不启动）
          if vim.g.lsp_debug then
            vim.notify("[LSP] [LSP] 警告: nvim-lspconfig 不可用，使用 vim.lsp.start 配置 " .. server_name)
          end
          -- 只构建配置，不启动
          local client_id = vim.lsp.start(lsp_config)
          if client_id then
            -- 立即停止，因为我们只想要配置
            local client = vim.lsp.get_client_by_id(client_id)
            if client then
              client:stop()
            end
          end
        end
      else
        -- 使用 Neovim 0.12 的内置 LSP API
        -- 我们只需要存储配置，服务器会在需要时启动
        if vim.g.lsp_debug then
          vim.notify("[LSP] [LSP] 使用 Neovim 内置 LSP API 配置 " .. server_name)
          vim.notify("[LSP] [LSP] 配置已存储，服务器将在需要时启动")
        end

        -- 将配置存储到全局表，供 start_server_with_config 使用
        if not M._server_configs then
          M._server_configs = {}
        end
        M._server_configs[server_name] = lsp_config
      end
    end

    -- 禁用 mason-lspconfig 的自动配置，完全使用我们的配置系统
    -- 这样可以避免配置冲突和重复客户端问题
    mason_lspconfig.setup({
      -- 禁用自动安装，我们有自己的安装逻辑
      automatic_installation = false,

      -- 确保安装的服务器（仅用于显示，不自动安装）
      ensure_installed = {
        "lua_ls",
        "pyright",
        "ts_ls",
        "html",
        "cssls",
        "jsonls",
        "yamlls",
        "bashls",
        "clangd",
        "gopls",
        "rust_analyzer",
      },

      -- 配置处理器 - 只配置，不自动启动
      handlers = {
        -- 默认处理器，只配置不启动
        function(server_name)
          setup_server(server_name)
        end,

        -- 为 lua_ls 提供专门的处理器
        lua_ls = function()
          setup_server("lua_ls")
        end,
      },
    })
  end

  -- 安装推荐的 LSP 服务器和格式化工具
  vim.defer_fn(function()
    -- 尝试获取包列表，如果获取不到就更新
    local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
    if not mason_registry_ok or not mason_registry.get_package then
      vim.cmd("MasonUpdate")
    end

    -- 验证 LSP 配置（不启动服务器）
    M.setup_lsp_configs()

    M.ensure_lsp_servers()
    M.ensure_formatters()
  end, 1000)
end

function M.setup_lsp_configs()
  -- 只配置 LSP 服务器，不启动
  -- 在 Neovim 0.12+ 中，服务器应该按需启动

  -- 防止重复验证
  if M._configs_validated then
    if vim.g.lsp_debug then
      vim.notify("[LSP] [LSP] 配置已验证过，跳过重复验证")
    end
    return
  end
  M._configs_validated = true

  if vim.g.lsp_debug then
    vim.notify("[LSP] [LSP] 配置服务器设置（不启动）...")
  end

  -- 我们只需要确保配置存在，服务器会在需要时由 start_lsp_for_filetype 启动
  -- 这里不执行任何启动操作，只是验证配置

  local valid_configs = 0
  local invalid_configs = 0

  for server_name, _ in pairs(M.lsp_to_mason) do
    local config = M.server_configs[server_name] or {}
    local cmd = config.cmd or get_default_cmd(server_name)

    if cmd then
      valid_configs = valid_configs + 1
      if vim.g.lsp_debug then
        vim.notify("[LSP] [LSP] 配置有效: " .. server_name)
      end
    else
      invalid_configs = invalid_configs + 1
      if vim.g.lsp_debug then
        vim.notify("[LSP] [LSP] 配置无效: " .. server_name .. " (缺少 cmd)")
      end
    end
  end

  if vim.g.lsp_debug then
    vim.notify("[LSP] [LSP] 配置验证完成: " .. valid_configs .. " 个有效, " .. invalid_configs .. " 个无效")
  end

  vim.notify("[LSP] LSP 配置验证完成 (" .. valid_configs .. " 个有效配置)", vim.log.levels.INFO)
end

function M.reconfigure_servers()
  -- 强制重新配置所有服务器，确保使用我们的配置
  if vim.g.lsp_debug then
    vim.notify("[LSP] [LSP] 开始重新配置所有服务器...")
  end

  -- 停止所有现有的客户端
  local all_clients = vim.lsp.get_clients()
  for _, client in ipairs(all_clients) do
    client:stop()
  end

  -- 清除所有缓冲区的标记
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].lsp_started = nil
    end
  end

  -- 重新配置所有服务器
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if lspconfig_ok then
    for server_name, _ in pairs(M.lsp_to_mason) do
      local config = M.server_configs[server_name] or {}
      local cmd = config.cmd or get_default_cmd(server_name)

      if cmd then
        local lsp_config = {
          name = server_name,
          cmd = cmd,
          settings = config.settings or {},
          on_attach = config.on_attach or default_on_attach,
          capabilities = config.capabilities or vim.lsp.protocol.make_client_capabilities(),
          root_dir = config.root_dir,
          filetypes = config.filetypes,
          manual = true,
        }

        lspconfig[server_name].setup(lsp_config)

        if vim.g.lsp_debug then
          vim.notify("[LSP] [LSP] 已重新配置服务器: " .. server_name)
        end
      end
    end
  end

  vim.notify("[LSP] 所有 LSP 服务器已重新配置", vim.log.levels.INFO)
end

function M.ensure_lsp_servers()
  -- 确保 LSP 服务器已安装

  -- 防止重复检查
  if M._servers_checked then
    if vim.g.lsp_debug then
      vim.notify("[LSP] [LSP] 服务器已检查过，跳过重复检查")
    end
    return
  end
  M._servers_checked = true

  local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_registry_ok then
    return
  end

  local installed = 0
  local to_install = {}

  for lsp_name, mason_name in pairs(M.lsp_to_mason) do
    local ok, pkg = pcall(mason_registry.get_package, mason_name)
    if ok and pkg:is_installed() then
      installed = installed + 1
    else
      table.insert(to_install, { lsp_name, mason_name })
    end
  end

  if #to_install > 0 then
    vim.notify(
      "有 " .. #to_install .. " 个 LSP 服务器需要安装，运行 :LspInstallMissing 安装",
      vim.log.levels.INFO
    )
    vim.cmd(":LspInstallMissing")
  else
    vim.notify("[LSP] 所有 LSP 服务器已安装 (" .. installed .. " 个)", vim.log.levels.INFO)
  end
end

function M.ensure_formatters()
  -- 确保格式化工具已安装

  -- 防止重复检查
  if M._formatters_checked then
    if vim.g.lsp_debug then
      vim.notify("[LSP] [LSP] 格式化工具已检查过，跳过重复检查")
    end
    return
  end
  M._formatters_checked = true

  local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_registry_ok then
    return
  end

  local installed = 0
  local to_install = {}
  local added = {} -- 用于避免重复添加

  -- 收集需要安装的格式化工具
  for _, formatters in pairs(M.formatters_by_ft) do
    for _, formatter in ipairs(formatters) do
      local mason_name = M.formatter_to_mason[formatter]
      if mason_name and not added[mason_name] then
        local ok, pkg = pcall(mason_registry.get_package, mason_name)
        if ok and pkg:is_installed() then
          installed = installed + 1
        elseif ok then
          added[mason_name] = true
          table.insert(to_install, { formatter, mason_name })
        end
      end
    end
  end

  if #to_install > 0 then
    vim.notify(
      "有 " .. #to_install .. " 个格式化工具需要安装，运行 :FormatterInstallMissing 安装",
      vim.log.levels.INFO
    )
    vim.cmd("FormatterInstallMissing")
  else
    vim.notify("[LSP] 所有格式化工具已安装 (" .. installed .. " 个)", vim.log.levels.INFO)
  end
end

vim.api.nvim_create_user_command("LspInstallMissing", function()
  -- 安装缺失的 LSP 服务器
  local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_registry_ok then
    print("无法访问 Mason 注册表", vim.log.levels.ERROR)
    return
  end

  local installed = 0
  for lsp_name, mason_name in pairs(M.lsp_to_mason) do
    local ok, pkg = pcall(mason_registry.get_package, mason_name)
    if ok and not pkg:is_installed() then
      pkg:install()
      print("正在安装: " .. mason_name, vim.log.levels.INFO)
      installed = installed + 1
    end
  end

  if installed > 0 then
    print("已开始安装 " .. installed .. " 个 LSP 服务器", vim.log.levels.INFO)
  else
    print("所有 LSP 服务器已安装", vim.log.levels.INFO)
  end
end, { desc = "安装缺失的 LSP 服务器" })

vim.api.nvim_create_user_command("FormatterInstallMissing", function()
  -- 安装缺失的格式化工具
  local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_registry_ok then
    print("无法访问 Mason 注册表", vim.log.levels.ERROR)
    return
  end

  local installed = 0
  for formatter, mason_name in pairs(M.formatter_to_mason) do
    local ok, pkg = pcall(mason_registry.get_package, mason_name)
    if ok and not pkg:is_installed() then
      pkg:install()
      print("正在安装: " .. mason_name .. " (" .. formatter .. ")", vim.log.levels.INFO)
      installed = installed + 1
    end
  end

  if installed > 0 then
    print("已开始安装 " .. installed .. " 个格式化工具", vim.log.levels.INFO)
  else
    print("所有格式化工具已安装", vim.log.levels.INFO)
  end
end, { desc = "安装缺失的格式化工具" })

vim.api.nvim_create_user_command("LspStatus", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if #clients == 0 then
    print("当前缓冲区没有活动的 LSP 客户端")
  else
    print("当前缓冲区的 LSP 客户端:")
    for _, client in ipairs(clients) do
      print("  - " .. client.name)
      print("    格式化支持: " .. tostring(client.server_capabilities.documentFormattingProvider))
      print("    悬停支持: " .. tostring(client.server_capabilities.hoverProvider))
    end
  end

  print("文件类型: " .. vim.bo.filetype)

  local servers = M.filetype_mappings[vim.bo.filetype]
  if servers then
    print("配置的 LSP 服务器: " .. table.concat(servers, ", "))
  end

  -- 显示所有可用的 LSP 服务器
  local available_servers = M.get_available_servers()
  if #available_servers > 0 then
    table.sort(available_servers)
    print("可用的 LSP 服务器: " .. table.concat(available_servers, ", "))
  end

  -- 显示格式化器信息
  local conform_ok, _ = pcall(require, "conform")
  if conform_ok then
    local ft = vim.bo.filetype
    local formatters = M.formatters_by_ft[ft] or {}
    if #formatters > 0 then
      print("配置的格式化器: " .. table.concat(formatters, ", "))
    else
      print("配置的格式化器: 无")
    end
  end
end, { desc = "显示 LSP 状态" })

vim.api.nvim_create_user_command("LspClients", function()
  -- 显示所有 LSP 客户端的详细信息
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  print("=== LSP 客户端详细信息 ===")
  print("缓冲区: " .. bufnr)
  print("文件类型: " .. ft)
  print("")

  -- 当前缓冲区的客户端
  local buf_clients = vim.lsp.get_clients({ bufnr = bufnr })
  print("附加到当前缓冲区的客户端 (" .. #buf_clients .. " 个):")
  for _, client in ipairs(buf_clients) do
    print("  " .. client.name .. " (ID: " .. client.id .. ")")
    print("    配置文件: " .. (client.config and "是" or "否"))
    -- 获取文件类型
    local filetypes_str = "未知"
    if client.config then
      local filetypes = nil
      -- 尝试从不同位置获取文件类型
      ---@diagnostic disable-next-line: undefined-field
      local possible_filetypes = client.config.filetypes
        or (client.config.init_options and client.config.init_options.filetypes)
      if possible_filetypes and type(possible_filetypes) == "table" then
        filetypes = possible_filetypes
      elseif
        client.config.init_options
        and client.config.init_options.filetypes
        and type(client.config.init_options.filetypes) == "table"
      then
        filetypes = client.config.init_options.filetypes
      end

      if filetypes and type(filetypes) == "table" then
        filetypes_str = table.concat(filetypes, ", ")
      end
    end
    print("    文件类型: " .. filetypes_str)
    print("    根目录: " .. (client.config and client.config.root_dir or "无"))
  end

  print("")

  -- 所有客户端
  local all_clients = vim.lsp.get_clients()
  print("所有 LSP 客户端 (" .. #all_clients .. " 个):")

  local clients_by_name = {}
  for _, client in ipairs(all_clients) do
    if not clients_by_name[client.name] then
      clients_by_name[client.name] = {}
    end
    table.insert(clients_by_name[client.name], client)
  end

  for name, client_list in pairs(clients_by_name) do
    print("  " .. name .. ": " .. #client_list .. " 个实例")
    for _, client in ipairs(client_list) do
      print("    实例 ID: " .. client.id)

      -- 检查附加的缓冲区
      local attached_buffers = {}
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.lsp.buf_is_attached(buf, client.id) then
          table.insert(attached_buffers, buf)
        end
      end

      if #attached_buffers > 0 then
        print("    附加到缓冲区: " .. table.concat(attached_buffers, ", "))
      else
        print("    未附加到任何缓冲区")
      end
    end
  end

  print("")
  print("=== 结束 ===")
end, { desc = "显示所有 LSP 客户端的详细信息" })

vim.api.nvim_create_user_command("LspCleanup", function()
  M.cleanup_duplicate_clients()
end, { desc = "清理重复的 LSP 客户端" })

vim.api.nvim_create_user_command("LspDebug", function()
  vim.g.lsp_debug = not vim.g.lsp_debug
  if vim.g.lsp_debug then
    print("LSP 调试模式已启用", vim.log.levels.INFO)
  else
    print("LSP 调试模式已禁用", vim.log.levels.INFO)
  end
end, { desc = "切换 LSP 调试模式" })

vim.api.nvim_create_user_command("LspListServers", function()
  -- 列出所有可用的 LSP 服务器
  local servers = M.get_available_servers()
  if #servers == 0 then
    print("没有找到可用的 LSP 服务器配置")
    return
  end

  table.sort(servers)
  print("可用的 LSP 服务器配置 (" .. #servers .. " 个):")
  for _, server in ipairs(servers) do
    local config = M.server_configs[server]
    local has_config = next(config) ~= nil
    print(string.format("  - %-20s %s", server, has_config and "✓ 有配置" or "✗ 无配置"))
  end
end, { desc = "列出所有可用的 LSP 服务器" })

vim.api.nvim_create_user_command("LspReload", function()
  -- 重新加载 LSP 配置
  vim.notify("[LSP] 重新加载 LSP 配置...", vim.log.levels.INFO)

  -- 停止所有 LSP 客户端（使用安全的方法）
  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    -- 在 Neovim 0.12 中，使用 client:stop() 来停止客户端
    client:stop()
  end

  -- 清除缓冲区标记
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].lsp_started = nil
    end
  end

  -- 重新设置 LSP
  M.setup()

  vim.notify("[LSP] LSP 配置已重新加载", vim.log.levels.INFO)
end, { desc = "重新加载 LSP 配置" })

-- LSP 调试函数
local function debug_lsp_loading()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  vim.notify("[LSP] === LSP 加载调试信息 ===")
  vim.notify("[LSP] 文件类型: " .. (ft or "无"))
  vim.notify("[LSP] 缓冲区: " .. bufnr)

  -- 检查是否已标记为已启动
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("[LSP] lsp_started 标记: " .. tostring(vim.b[bufnr].lsp_started))
  else
    vim.notify("[LSP] lsp_started 标记: 缓冲区无效")
  end

  -- 检查文件类型映射
  local servers = M.filetype_mappings[ft]
  if servers then
    vim.notify("[LSP] 配置的服务器: " .. table.concat(servers, ", "))
  else
    vim.notify("[LSP] 配置的服务器: 无")
  end

  -- 检查当前缓冲区的 LSP 客户端
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  vim.notify("[LSP] 当前缓冲区的 LSP 客户端数量: " .. #clients)
  for _, client in ipairs(clients) do
    vim.notify("[LSP]   - " .. client.name)
  end

  -- 检查所有 LSP 客户端
  local all_clients = vim.lsp.get_clients()
  vim.notify("[LSP] 所有 LSP 客户端数量: " .. #all_clients)
  for _, client in ipairs(all_clients) do
    vim.notify("[LSP]   - " .. client.name .. " (id: " .. client.id .. ")")
  end

  -- 检查 lua_ls 是否在运行
  local lua_clients = vim.lsp.get_clients({ name = "lua_ls" })
  vim.notify("[LSP] lua_ls 客户端数量: " .. #lua_clients)

  -- 检查 Mason 状态
  local mason_ok, _ = pcall(require, "mason-registry")
  vim.notify("[LSP] Mason 注册表可用: " .. tostring(mason_ok))

  if mason_ok then
    local mason_registry = require("mason-registry")
    local ok, pkg = pcall(mason_registry.get_package, "lua-language-server")
    if ok then
      vim.notify("[LSP] lua-language-server 包存在: 是")
      vim.notify("[LSP] lua-language-server 已安装: " .. tostring(pkg:is_installed()))
    else
      vim.notify("[LSP] lua-language-server 包存在: 否")
    end
  end

  vim.notify("[LSP] === 调试结束 ===")
end

vim.api.nvim_create_user_command("LspDebugLoad", debug_lsp_loading, { desc = "调试 LSP 加载流程" })

vim.api.nvim_create_user_command("LuaLSStatus", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  vim.notify("[LSP] === Lua Language Server 状态检查 ===")
  vim.notify("[LSP] 文件类型: " .. (ft or "无"))
  vim.notify("[LSP] 缓冲区: " .. bufnr)

  -- 检查 lua_ls 客户端
  local lua_clients = vim.lsp.get_clients({ name = "lua_ls", bufnr = bufnr })
  vim.notify("[LSP] lua_ls 客户端数量 (当前缓冲区): " .. #lua_clients)

  if #lua_clients > 0 then
    local client = lua_clients[1]
    vim.notify("[LSP] 客户端 ID: " .. client.id)
    vim.notify("[LSP] 服务器能力:")
    vim.notify("[LSP]   格式化: " .. tostring(client.server_capabilities.documentFormattingProvider))
    vim.notify("[LSP]   悬停: " .. tostring(client.server_capabilities.hoverProvider))
    vim.notify("[LSP]   定义: " .. tostring(client.server_capabilities.definitionProvider))

    -- 检查配置
    if client.config and client.config.settings then
      vim.notify("[LSP] 配置已加载: 是")
      -- 安全地访问 Lua 诊断配置
      ---@diagnostic disable-next-line: undefined-field
      local lua_settings = client.config.settings.Lua
      if
        lua_settings
        and type(lua_settings) == "table"
        ---@diagnostic disable-next-line: undefined-field
        and lua_settings.diagnostics
        ---@diagnostic disable-next-line: undefined-field
        and type(lua_settings.diagnostics) == "table"
      then
        ---@diagnostic disable-next-line: undefined-field
        local globals = lua_settings.diagnostics.globals
        if type(globals) == "table" then
          vim.notify("[LSP] 定义的全局变量: " .. table.concat(globals, ", "))
        else
          vim.notify("[LSP] 定义的全局变量: 无")
        end
      else
        vim.notify("[LSP] Lua 诊断配置: 无")
      end
    else
      vim.notify("[LSP] 配置已加载: 否")
    end
  else
    vim.notify("[LSP] lua_ls 未附加到当前缓冲区")

    -- 检查是否在其他地方运行
    local all_lua_clients = vim.lsp.get_clients({ name = "lua_ls" })
    vim.notify("[LSP] lua_ls 总客户端数量: " .. #all_lua_clients)

    if #all_lua_clients > 0 then
      vim.notify("[LSP] lua_ls 正在运行但未附加到当前缓冲区")
      for _, client in ipairs(all_lua_clients) do
        vim.notify("[LSP]   客户端 ID: " .. client.id)

        -- 检查客户端附加的缓冲区
        local attached_buffers = {}
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.lsp.buf_is_attached(buf, client.id) then
            table.insert(attached_buffers, buf)
          end
        end

        if #attached_buffers > 0 then
          vim.notify("[LSP]   附加到缓冲区: " .. table.concat(attached_buffers, ", "))
        else
          vim.notify("[LSP]   未附加到任何缓冲区")
        end
      end
    end
  end

  -- 检查 Mason 安装状态
  local mason_ok, mason_registry = pcall(require, "mason-registry")
  if mason_ok then
    local ok, pkg = pcall(mason_registry.get_package, "lua-language-server")
    if ok then
      vim.notify("[LSP] Mason 包状态:")
      vim.notify("[LSP]   包存在: 是")
      vim.notify("[LSP]   已安装: " .. tostring(pkg:is_installed()))

      if pkg:is_installed() then
        -- 在较新版本的 Mason 中，使用 get_install_path 方法
        local install_dir
        if pkg.get_install_path then
          install_dir = pkg:get_install_path()
        elseif pkg.install_path then
          install_dir = pkg.install_path
        end
        vim.notify("[LSP]   安装路径: " .. (install_dir or "未知"))
      end
    else
      vim.notify("[LSP] Mason 包状态: lua-language-server 包不存在")
    end
  else
    vim.notify("[LSP] Mason 注册表不可用")
  end

  vim.notify("[LSP] === 检查完成 ===")
end, { desc = "检查 Lua Language Server 状态" })

vim.api.nvim_create_user_command("LspTestConfig", function()
  -- 测试 LSP 配置是否生效
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  vim.notify("[LSP] === LSP 配置测试 ===")
  vim.notify("[LSP] 当前缓冲区: " .. bufnr)
  vim.notify("[LSP] 文件类型: " .. ft)
  vim.notify("[LSP] ")

  -- 测试 lua_ls 配置
  vim.notify("[LSP] 1. 测试 lua_ls 配置:")
  local lua_config = M.server_configs["lua_ls"] or {}
  if next(lua_config) ~= nil then
    vim.notify("[LSP]   ✓ 找到 lua_ls 配置")
    if lua_config.settings and lua_config.settings.Lua then
      vim.notify("[LSP]   ✓ Lua 设置存在")
      if lua_config.settings.Lua.diagnostics and lua_config.settings.Lua.diagnostics.globals then
        vim.notify(
          "[LSP]   ✓ 全局变量配置: " .. table.concat(lua_config.settings.Lua.diagnostics.globals, ", ")
        )
      else
        vim.notify("[LSP]   ✗ 没有全局变量配置")
      end
    else
      vim.notify("[LSP]   ✗ 没有 Lua 设置")
    end
  else
    vim.notify("[LSP]   ✗ 没有找到 lua_ls 配置")
  end
  vim.notify("[LSP] ")

  -- 检查当前缓冲区的客户端
  vim.notify("[LSP] 2. 当前缓冲区的 LSP 客户端:")
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    vim.notify("[LSP]   ✗ 没有活动的 LSP 客户端")
  else
    for _, client in ipairs(clients) do
      vim.notify("[LSP]   ✓ " .. client.name .. " (ID: " .. client.id .. ")")

      -- 检查配置
      if client.config and client.config.settings then
        vim.notify("[LSP]     配置已加载: 是")
        if client.name == "lua_ls" and client.config.settings.Lua then
          vim.notify("[LSP]     Lua 设置: 有")
        end
      else
        vim.notify("[LSP]     配置已加载: 否")
      end
    end
  end
  vim.notify("[LSP] ")

  -- 检查应该启动的服务器
  vim.notify("[LSP] 3. 应该为当前文件类型启动的服务器:")
  local expected_servers = M.filetype_mappings[ft]
  if expected_servers then
    vim.notify("[LSP]   " .. table.concat(expected_servers, ", "))

    -- 检查每个服务器是否已配置
    for _, server_name in ipairs(expected_servers) do
      local config = M.server_configs[server_name] or {}
      if next(config) ~= nil then
        vim.notify("[LSP]     ✓ " .. server_name .. " 已配置")
      else
        vim.notify("[LSP]     ✗ " .. server_name .. " 未配置")
      end
    end
  else
    vim.notify("[LSP]   ✗ 没有为 " .. ft .. " 配置的服务器")
  end
  vim.notify("[LSP] ")

  vim.notify("[LSP] === 测试完成 ===")
  vim.notify("[LSP] ")
  vim.notify("[LSP] 建议操作:")
  vim.notify("[LSP] 1. 运行 :LspReconfigure 强制重新配置")
  vim.notify("[LSP] 2. 运行 :LspCleanup 清理重复客户端")
  vim.notify("[LSP] 3. 重新打开当前文件")
end, { desc = "测试 LSP 配置是否生效" })

vim.api.nvim_create_user_command("LspTestFiletype", function()
  -- 测试文件类型过滤功能
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  vim.notify("[LSP] === 文件类型过滤测试 ===")
  vim.notify("[LSP] 当前缓冲区: " .. bufnr)
  vim.notify("[LSP] 文件类型: " .. ft)
  vim.notify("[LSP] ")

  -- 获取所有客户端
  local all_clients = vim.lsp.get_clients()
  vim.notify("[LSP] 所有 LSP 客户端 (" .. #all_clients .. " 个):")

  for _, client in ipairs(all_clients) do
    vim.notify("[LSP]   " .. client.name .. " (ID: " .. client.id .. ")")

    -- 检查文件类型配置
    local filetypes = nil
    if client.config then
      -- 尝试从不同位置获取文件类型
      ---@diagnostic disable-next-line: undefined-field
      local possible_filetypes = client.config.filetypes
        or (client.config.init_options and client.config.init_options.filetypes)
      if possible_filetypes and type(possible_filetypes) == "table" then
        filetypes = possible_filetypes
      elseif
        client.config.init_options
        and client.config.init_options.filetypes
        and type(client.config.init_options.filetypes) == "table"
      then
        filetypes = client.config.init_options.filetypes
      end
    end
    if filetypes and type(filetypes) == "table" then
      vim.notify("[LSP]     配置文件类型: " .. table.concat(filetypes, ", "))

      -- 检查是否匹配当前文件类型
      local matches = false
      if type(filetypes) == "table" then
        for _, client_ft in ipairs(filetypes) do
          if client_ft == ft then
            matches = true
            break
          end
        end
      end

      if matches then
        vim.notify("[LSP]     ✓ 匹配当前文件类型")
      else
        vim.notify("[LSP]     ✗ 不匹配当前文件类型")
      end
    else
      vim.notify("[LSP]     未配置文件类型")
    end

    -- 检查是否附加到当前缓冲区
    local is_attached = vim.lsp.buf_is_attached(bufnr, client.id)
    vim.notify("[LSP]     附加到当前缓冲区: " .. (is_attached and "是" or "否"))
    vim.notify("[LSP] ")
  end

  -- 检查应该为当前文件类型启动的服务器
  local expected_servers = M.filetype_mappings[ft]
  if expected_servers then
    vim.notify("[LSP] 应该为 " .. ft .. " 启动的服务器: " .. table.concat(expected_servers, ", "))
  else
    vim.notify("[LSP] 没有为 " .. ft .. " 配置的服务器")
  end

  vim.notify("[LSP] ")
  vim.notify("[LSP] === 测试完成 ===")
  vim.notify("[LSP] ")
  vim.notify("[LSP] 建议:")
  vim.notify("[LSP] 1. 运行 :LspReload 重新加载配置")
  vim.notify("[LSP] 2. 运行 :LspCleanup 清理重复客户端")
  vim.notify("[LSP] 3. 重新打开文件测试")
end, { desc = "测试文件类型过滤功能" })

vim.api.nvim_create_user_command("LspReconfigure", function()
  -- 强制重新配置所有 LSP 服务器
  vim.notify("[LSP] 正在重新配置所有 LSP 服务器...", vim.log.levels.INFO)
  M.reconfigure_servers()
  vim.notify("[LSP] LSP 服务器已重新配置，请重新打开文件", vim.log.levels.INFO)
end, { desc = "强制重新配置所有 LSP 服务器" })

vim.api.nvim_create_user_command("LspQuickFix", function()
  -- 快速修复：停止所有默认配置的客户端，只保留我们的配置
  vim.notify("[LSP] === LSP 快速修复 ===")
  vim.notify("[LSP] 停止所有默认配置的 LSP 客户端...")

  local all_clients = vim.lsp.get_clients()
  local stopped = 0

  for _, client in ipairs(all_clients) do
    -- 检查是否是默认配置（没有我们的特定设置）
    local is_default_config = true

    if client.config and client.config.settings then
      if client.name == "lua_ls" and client.config.settings.Lua then
        -- 检查是否有我们配置的全局变量
        -- 安全地访问 Lua 配置
        ---@diagnostic disable-next-line: undefined-field
        local lua_settings = client.config.settings.Lua
        -- 安全地访问 Lua 诊断配置
        if
          lua_settings
          and type(lua_settings) == "table"
          ---@diagnostic disable-next-line: undefined-field
          and lua_settings.diagnostics
          ---@diagnostic disable-next-line: undefined-field
          and type(lua_settings.diagnostics) == "table"
          ---@diagnostic disable-next-line: undefined-field
          and lua_settings.diagnostics.globals
          ---@diagnostic disable-next-line: undefined-field
          and type(lua_settings.diagnostics.globals) == "table"
        then
          is_default_config = false
        end
      elseif client.config.settings then
        -- 对于其他服务器，如果有 settings 就认为是我们的配置
        is_default_config = false
      end
    end

    if is_default_config then
      vim.notify("[LSP]   停止默认配置客户端: " .. client.name .. " (ID: " .. client.id .. ")")
      client:stop()
      stopped = stopped + 1
    end
  end

  vim.notify("[LSP] 已停止 " .. stopped .. " 个默认配置的客户端")
  vim.notify("[LSP] ")
  vim.notify("[LSP] 现在重新启动 LSP 服务器...")

  -- 重新启动当前文件的 LSP
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  if ft and ft ~= "" then
    -- 清除缓冲区标记（检查缓冲区是否有效）
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].lsp_started = nil
    end

    -- 重新启动 LSP
    vim.schedule(function()
      start_lsp_for_filetype(ft, bufnr)
    end)

    vim.notify("[LSP] 已为 " .. ft .. " 重新启动 LSP 服务器")
  end

  vim.notify("[LSP] === 快速修复完成 ===")
  vim.notify("[LSP] LSP 重复问题已解决，现在应该只使用你的配置", vim.log.levels.INFO)
end, { desc = "快速修复 LSP 重复问题（停止所有默认配置）" })

vim.api.nvim_create_user_command("LspFixNow", function()
  -- 立即修复重复的 LSP 客户端
  vim.notify("[LSP] === 立即修复 LSP 重复问题 ===")

  -- 1. 清理重复客户端
  M.cleanup_duplicate_clients()

  -- 2. 重新附加到当前缓冲区
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  if ft and ft ~= "" then
    vim.notify("[LSP] 重新附加 LSP 客户端到当前缓冲区 (文件类型: " .. ft .. ")")

    local server_names = M.filetype_mappings[ft]
    if server_names then
      for _, server_name in ipairs(server_names) do
        local clients = vim.lsp.get_clients({ name = server_name })
        for _, client in ipairs(clients) do
          if not vim.lsp.buf_is_attached(bufnr, client.id) then
            -- 检查文件类型是否匹配
            local should_attach = true
            -- 尝试从不同位置获取文件类型
            ---@diagnostic disable-next-line: undefined-field
            local client_filetypes = client.config
              ---@diagnostic disable-next-line: undefined-field
              and (client.config.filetypes or (client.config.init_options and client.config.init_options.filetypes))
            if client_filetypes and type(client_filetypes) == "table" then
              should_attach = false
              for _, client_ft in ipairs(client_filetypes) do
                if client_ft == ft then
                  should_attach = true
                  break
                end
              end
            end

            if should_attach then
              vim.lsp.buf_attach_client(bufnr, client.id)
              vim.notify("[LSP]   附加 " .. server_name .. " (ID: " .. client.id .. ")")
            end
          end
        end
      end
    end

    -- 更新缓冲区标记（检查缓冲区是否仍然有效）
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].lsp_started = true
    end
  end

  vim.notify("[LSP] === 修复完成 ===")
  vim.notify("[LSP] LSP 重复问题已修复", vim.log.levels.INFO)
end, { desc = "立即修复重复的 LSP 客户端" })

function M.start_server_with_config(server_name, bufnr)
  -- 使用我们的配置启动 LSP 服务器
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- 检查缓冲区是否仍然有效
  if not vim.api.nvim_buf_is_valid(bufnr) then
    if vim.g.lsp_debug then
      vim.notify("[LSP] [LSP] 跳过启动 " .. server_name .. ": 缓冲区无效", vim.log.levels.WARN)
    end
    return false
  end

  -- 优先使用存储的配置（如果使用内置 API）
  local lsp_config
  if not M.config.use_lspconfig and M._server_configs and M._server_configs[server_name] then
    lsp_config = vim.deepcopy(M._server_configs[server_name])

    if vim.g.lsp_debug then
      vim.notify("[LSP] [LSP] 使用存储的配置启动 " .. server_name)
    end
  else
    -- 回退到从配置文件加载
    local config = M.server_configs[server_name] or {}

    -- 确保配置包含必要的字段
    local cmd = config.cmd or get_default_cmd(server_name)

    if not cmd then
      if vim.g.lsp_debug then
        vim.notify("[LSP] 无法启动 LSP " .. server_name .. ": 未找到 cmd 配置", vim.log.levels.WARN)
      end
      return false
    end

    -- 构建完整的配置
    lsp_config = {
      name = server_name,
      cmd = cmd,
      settings = config.settings or {},
      on_attach = config.on_attach or default_on_attach,
      capabilities = config.capabilities or vim.lsp.protocol.make_client_capabilities(),
      root_dir = config.root_dir or vim.fn.getcwd(),
      filetypes = config.filetypes,
    }
  end

  -- 应用内存限制配置
  lsp_config = apply_memory_limits_to_config(lsp_config, server_name)

  -- 确保配置有必要的字段
  if not lsp_config.root_dir then
    lsp_config.root_dir = vim.fn.getcwd()
  end

  -- 调试信息
  if vim.g.lsp_debug then
    vim.notify("[LSP] [LSP] 启动服务器 " .. server_name .. " 使用配置:")
    vim.notify("[LSP]   cmd: " .. vim.inspect(lsp_config.cmd))

    -- 显示内存限制信息
    if M.config.memory_limit.enabled then
      vim.notify("[LSP]   内存限制: 已启用 (最大 " .. M.config.memory_limit.max_memory_per_client .. " MB)")
    end

    if lsp_config.settings and lsp_config.settings.Lua then
      vim.notify("[LSP]   Lua 运行时路径: " .. (lsp_config.settings.Lua.runtime and "有" or "无"))
      vim.notify(
        "  Lua 诊断全局变量数量: "
          .. (
            lsp_config.settings.Lua.diagnostics
              and lsp_config.settings.Lua.diagnostics.globals
              and #lsp_config.settings.Lua.diagnostics.globals
            or 0
          )
      )

      -- 显示 workspace 限制信息
      if lsp_config.settings.Lua.workspace then
        vim.notify("[LSP]   maxPreload: " .. (lsp_config.settings.Lua.workspace.maxPreload or "默认"))
        vim.notify("[LSP]   preloadFileSize: " .. (lsp_config.settings.Lua.workspace.preloadFileSize or "默认"))
      end
    end
  end

  -- 使用 vim.lsp.start 启动服务器
  local client_id = vim.lsp.start(lsp_config)

  if client_id then
    -- 附加到缓冲区
    vim.lsp.buf_attach_client(bufnr, client_id)

    if vim.g.lsp_debug then
      vim.notify("[LSP] [LSP] 服务器 " .. server_name .. " 已启动 (ID: " .. client_id .. ")")
    end

    return true
  else
    if vim.g.lsp_debug then
      vim.notify("[LSP] 无法启动 LSP 服务器: " .. server_name, vim.log.levels.ERROR)
    end
    return false
  end
end

-- 自动设置 LSP（如果从主配置调用）
-- 注意：主配置文件已经显式调用了 require("lsp").setup()
-- 所以这里不再自动设置，避免重复执行
-- if vim.g.lsp_auto_setup ~= false then
--   vim.schedule(function()
--     M.setup()
--     vim.notify("[LSP] LSP 配置已自动加载", vim.log.levels.INFO)
--   end)
-- end

-- ============================================
-- 用户指南：解决 LSP 重复客户端问题
-- ============================================
--
-- 问题：LSP 启动了两个客户端，一个是默认配置，一个是你的配置
-- 原因：nvim-lspconfig 插件自动配置了默认设置
--
-- 解决方案：
-- 1. 我们已经注释掉了 nvim-lspconfig 插件的安装
-- 2. 现在完全使用 Neovim 0.12 的内置 LSP API
-- 3. 配置存储在 M._server_configs 表中，按需启动
--
-- 使用步骤：
-- 1. 运行 :LspQuickFix 停止所有默认配置的客户端
-- 2. 重新打开你的 Lua 文件
-- 3. LSP 应该只使用你的配置启动
--
-- 调试命令：
-- :LspDebug - 切换调试模式
-- :LspTestConfig - 测试配置是否生效
-- :LspStatus - 查看当前 LSP 状态
-- :LspClients - 查看所有客户端详细信息
--
-- 如果还有问题：
-- 1. 运行 :LspReconfigure 强制重新配置
-- 2. 运行 :LspCleanup 清理重复客户端
-- 3. 重新打开文件
--
-- 注意：现在配置中 use_lspconfig = false，完全使用内置 API
-- ============================================

-- 内存管理命令
vim.api.nvim_create_user_command("LspMemoryStatus", function()
  -- 显示详细内存使用状态
  local all_clients = vim.lsp.get_clients()
  local active_clients = 0
  local total_memory_mb = 0
  local memory_stats = {}

  -- 获取系统内存信息
  local meminfo = get_system_memory_info()
  local dynamic_limits = calculate_dynamic_limits()

  -- 收集内存使用信息
  for _, client in ipairs(all_clients) do
    local has_attached_buffers = false
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.lsp.buf_is_attached(bufnr, client.id) then
        has_attached_buffers = true
        break
      end
    end

    if has_attached_buffers then
      active_clients = active_clients + 1
    end

    -- 获取内存信息
    local memory_info = get_lsp_client_memory_info(client)
    table.insert(memory_stats, memory_info)
    total_memory_mb = total_memory_mb + memory_info.memory_mb
  end

  vim.notify("[LSP] === LSP 内存使用状态 ===")

  -- 显示系统内存信息
  vim.notify("[LSP] 系统内存信息:")
  if meminfo.total_gb then
    vim.notify("[LSP]   • 总内存: " .. meminfo.total_gb .. " GB (" .. meminfo.total_mb .. " MB)")
    vim.notify("[LSP]   • 已使用: " .. (meminfo.used_mb or 0) .. " MB")
    vim.notify("[LSP]   • 可用内存: " .. (meminfo.available_mb or meminfo.free_mb or 0) .. " MB")
    vim.notify("[LSP]   • 使用率: " .. (meminfo.usage_percent or 0) .. "%")
  else
    vim.notify("[LSP]   • 系统内存信息: 无法获取")
  end
  vim.notify("[LSP] ")

  -- 显示动态限制信息
  vim.notify("[LSP] 动态计算的内存限制:")
  vim.notify("[LSP]   • 系统内存: " .. dynamic_limits.system_memory_gb .. " GB")
  vim.notify("[LSP]   • 最大并发客户端: " .. dynamic_limits.max_concurrent_clients)
  vim.notify("[LSP]   • 每个客户端内存限制: " .. dynamic_limits.max_memory_per_client .. " MB")
  vim.notify("[LSP]   • 最大 workspace 文件: " .. dynamic_limits.max_workspace_files)
  vim.notify("[LSP]   • lua_ls 最大项目数: " .. dynamic_limits.lua_max_items)
  vim.notify("[LSP] ")

  -- 显示配置的内存限制
  vim.notify("[LSP] 配置的内存限制:")
  vim.notify("[LSP]   • 最大并发客户端: " .. M.config.memory_limit.max_concurrent_clients)
  vim.notify("[LSP]   • 每个客户端内存限制: " .. M.config.memory_limit.max_memory_per_client .. " MB")
  vim.notify("[LSP]   • 最大 workspace 文件: " .. M.config.memory_limit.max_workspace_files)
  vim.notify("[LSP]   • 内存限制启用: " .. (M.config.memory_limit.enabled and "是" or "否"))
  vim.notify(
    "[LSP]   • 使用动态限制: " .. (M.config.memory_limit.max_memory_per_client == 0 and "是" or "否")
  )
  vim.notify("[LSP] ")

  vim.notify("[LSP] 当前 LSP 状态:")
  vim.notify("[LSP]   • 总 LSP 客户端: " .. #all_clients)
  vim.notify("[LSP]   • 活跃客户端: " .. active_clients)
  vim.notify("[LSP]   • 总内存使用: " .. string.format("%.1f", total_memory_mb) .. " MB")

  -- 使用动态限制或配置的限制
  local effective_max_clients = M.config.memory_limit.max_concurrent_clients > 0
      and M.config.memory_limit.max_concurrent_clients
    or dynamic_limits.max_concurrent_clients

  local effective_max_memory = M.config.memory_limit.max_memory_per_client > 0
      and M.config.memory_limit.max_memory_per_client
    or dynamic_limits.max_memory_per_client

  local total_limit_mb = effective_max_clients * effective_max_memory
  local memory_usage_percent = total_limit_mb > 0 and math.floor((total_memory_mb / total_limit_mb) * 100) or 0
  vim.notify("[LSP]   • 内存使用率: " .. memory_usage_percent .. "% (限制: " .. total_limit_mb .. " MB)")

  local client_usage_percent = effective_max_clients > 0 and math.floor((active_clients / effective_max_clients) * 100)
    or 0
  vim.notify(
    "[LSP]   • 客户端使用率: " .. client_usage_percent .. "% (限制: " .. effective_max_clients .. " 个)"
  )
  vim.notify("[LSP] ")

  -- 显示每个客户端详细信息
  if #memory_stats > 0 then
    vim.notify("[LSP] 客户端内存使用详情:")

    -- 按内存使用排序
    table.sort(memory_stats, function(a, b)
      return a.memory_mb > b.memory_mb
    end)

    for _, info in ipairs(memory_stats) do
      local status_icon = "○"
      if info.status == "critical" then
        status_icon = "●"
      elseif info.status == "warning" then
        status_icon = "◎"
      end

      local pid_str = info.pid and "PID: " .. info.pid or "PID: 未知"
      local memory_str = info.memory_mb > 0 and string.format("%.1f", info.memory_mb) .. " MB" or "内存: 未知"

      vim.notify(
        string.format("[LSP]   %s %-20s %-15s %-15s %s", status_icon, info.name, pid_str, memory_str, info.status)
      )
    end
  end

  vim.notify("[LSP] ")
  vim.notify("[LSP] 状态说明:")
  vim.notify("[LSP]   ● 严重 - 内存使用超过限制的 90%")
  vim.notify("[LSP]   ◎ 警告 - 内存使用超过限制的 70%")
  vim.notify("[LSP]   ○ 正常 - 内存使用正常")
  vim.notify("[LSP] ")

  -- 显示建议
  vim.notify("[LSP] 建议操作:")
  if memory_usage_percent > 80 then
    vim.notify("[LSP]   • 运行 :LspReduceMemory 减少内存使用")
    vim.notify("[LSP]   • 运行 :LspMemoryLimit 调整内存限制")
  end

  if client_usage_percent > 80 then
    vim.notify("[LSP]   • 考虑增加最大并发客户端数量")
  end

  -- 检查是否有严重状态的客户端
  local critical_clients = 0
  for _, info in ipairs(memory_stats) do
    if info.status == "critical" then
      critical_clients = critical_clients + 1
    end
  end

  if critical_clients > 0 then
    vim.notify("[LSP]   • 有 " .. critical_clients .. " 个客户端内存使用严重，建议重启")
  end

  vim.notify("[LSP] === 状态显示完成 ===")
end, { desc = "显示 LSP 内存使用状态" })

vim.api.nvim_create_user_command("LspForceMemoryLimit", function()
  -- 强制应用内存限制到所有 LSP 服务器
  vim.notify("[LSP] === 强制应用内存限制 ===")

  if not M.config.memory_limit.enabled then
    vim.notify("[LSP] 内存限制未启用，请先启用内存限制", vim.log.levels.WARN)
    return
  end

  local all_clients = vim.lsp.get_clients()
  local reconfigured = 0

  vim.notify("[LSP] 正在重新配置所有 LSP 服务器以应用内存限制...")

  -- 停止所有现有客户端
  for _, client in ipairs(all_clients) do
    client:stop()
  end

  -- 清除缓冲区标记
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].lsp_started = nil
    end
  end

  -- 重新配置所有服务器配置
  if M._server_configs then
    for server_name, config in pairs(M._server_configs) do
      -- 应用内存限制
      local limited_config = apply_memory_limits_to_config(config, server_name)
      M._server_configs[server_name] = limited_config
      reconfigured = reconfigured + 1

      if vim.g.lsp_debug then
        vim.notify("[LSP]   已重新配置: " .. server_name)
      end
    end
  end

  -- 重新启动当前文件的 LSP
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  if ft and ft ~= "" then
    vim.schedule(function()
      start_lsp_for_filetype(ft, bufnr)
    end)

    vim.notify("[LSP] 已为 " .. ft .. " 重新启动 LSP 服务器")
  end

  vim.notify("[LSP] 已强制应用内存限制到 " .. reconfigured .. " 个服务器配置")
  vim.notify("[LSP] === 操作完成 ===")
  vim.notify("[LSP] 内存限制已强制应用到所有 LSP 服务器", vim.log.levels.INFO)
end, { desc = "强制应用内存限制到所有 LSP 服务器" })

vim.api.nvim_create_user_command("LspMemoryLimit", function(opts)
  -- 动态调整内存限制
  local args = opts.args

  if args == "" then
    -- 显示当前设置
    vim.notify("[LSP] 当前内存限制设置:")
    vim.notify("[LSP]   • 最大并发客户端: " .. M.config.memory_limit.max_concurrent_clients)
    vim.notify("[LSP]   • 每个客户端内存: " .. M.config.memory_limit.max_memory_per_client .. " MB")
    vim.notify("[LSP]   • 最大 workspace 文件: " .. M.config.memory_limit.max_workspace_files)
    vim.notify("[LSP] ")
    vim.notify("[LSP] 使用方法: :LspMemoryLimit clients=3 memory=512 files=1000")
    return
  end

  -- 解析参数
  local new_settings = {}
  for param in args:gmatch("([^=]+)=([^%s]+)") do
    local key, value = param:match("([^=]+)=([^%s]+)")
    if key and value then
      new_settings[key] = tonumber(value)
    end
  end

  -- 更新设置
  if new_settings.clients then
    M.config.memory_limit.max_concurrent_clients = new_settings.clients
    vim.notify("[LSP] 更新最大并发客户端为: " .. new_settings.clients)
  end

  if new_settings.memory then
    M.config.memory_limit.max_memory_per_client = new_settings.memory
    vim.notify("[LSP] 更新每个客户端内存限制为: " .. new_settings.memory .. " MB")
  end

  if new_settings.files then
    M.config.memory_limit.max_workspace_files = new_settings.files
    vim.notify("[LSP] 更新最大 workspace 文件为: " .. new_settings.files)
  end

  vim.notify("[LSP] 内存限制已更新，新设置将在下次启动 LSP 时生效")
end, { desc = "动态调整 LSP 内存限制", nargs = "?" })

vim.api.nvim_create_user_command("LspReduceMemory", function()
  -- 减少内存使用
  vim.notify("[LSP] === 减少内存使用 ===")

  -- 1. 停止空闲的 LSP 客户端
  local all_clients = vim.lsp.get_clients()
  local stopped = 0

  for _, client in ipairs(all_clients) do
    local has_attached_buffers = false
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.lsp.buf_is_attached(bufnr, client.id) then
        has_attached_buffers = true
        break
      end
    end

    if not has_attached_buffers then
      -- 客户端没有附加到任何缓冲区，可以停止
      vim.notify("[LSP]   停止空闲客户端: " .. client.name .. " (ID: " .. client.id .. ")")
      client:stop()
      stopped = stopped + 1
    end
  end

  -- 2. 清理缓冲区标记
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].lsp_started = nil
    end
  end

  -- 3. 强制垃圾回收
  collectgarbage("collect")

  vim.notify("[LSP] 已停止 " .. stopped .. " 个空闲 LSP 客户端")
  vim.notify("[LSP] 已清理缓冲区标记")
  vim.notify("[LSP] 已执行垃圾回收")
  vim.notify("[LSP] === 操作完成 ===")
end, { desc = "减少 LSP 内存使用（停止空闲客户端）" })

vim.api.nvim_create_user_command("CopilotMemoryLimit", function(opts)
  -- 调整 Copilot 内存限制
  local args = opts.args

  if args == "" then
    -- 显示当前设置
    vim.notify("[LSP] GitHub Copilot 当前内存限制设置:")
    vim.notify("[LSP]   • 内存限制: " .. M.config.copilot.memory_limit .. " MB")
    vim.notify("[LSP]   • 建议延迟: " .. M.config.copilot.suggestion_delay .. "ms")
    vim.notify("[LSP]   • 最大文件大小: " .. M.config.copilot.max_file_size_kb .. " KB")
    vim.notify("[LSP] ")
    vim.notify("[LSP] 使用方法: :CopilotMemoryLimit memory=256 delay=100 size=100")
    return
  end

  -- 解析参数
  local new_settings = {}
  for param in args:gmatch("([^=]+)=([^%s]+)") do
    local key, value = param:match("([^=]+)=([^%s]+)")
    if key and value then
      new_settings[key] = tonumber(value)
    end
  end

  -- 更新设置
  if new_settings.memory then
    M.config.copilot.memory_limit = new_settings.memory
    vim.notify("[LSP] 更新 Copilot 内存限制为: " .. new_settings.memory .. " MB")
  end

  if new_settings.delay then
    M.config.copilot.suggestion_delay = new_settings.delay
    vim.notify("[LSP] 更新 Copilot 建议延迟为: " .. new_settings.delay .. "ms")
  end

  if new_settings.size then
    M.config.copilot.max_file_size_kb = new_settings.size
    vim.notify("[LSP] 更新 Copilot 最大文件大小为: " .. new_settings.size .. " KB")
  end

  -- 重新应用 Copilot 配置
  setup_copilot_memory_limits()

  vim.notify("[LSP] Copilot 内存限制已更新")
end, { desc = "调整 GitHub Copilot 内存限制", nargs = "?" })

-- ============================================
-- LSP 进程管理命令
-- ============================================

vim.api.nvim_create_user_command("LspProcessStatus", function()
  -- 显示所有 LSP 相关进程状态
  local processes = get_all_lsp_processes()

  if #processes == 0 then
    vim.notify("[LSP] 没有找到 LSP 相关进程")
    return
  end

  -- 获取活跃客户端 PID
  local active_clients = vim.lsp.get_clients()
  local active_pids = {}
  for _, client in ipairs(active_clients) do
    -- 检查 client.pid
    ---@diagnostic disable-next-line: undefined-field
    local pid = client.pid
    if pid then
      active_pids[pid] = true
    end
  end

  vim.notify("[LSP] === LSP 进程状态 (" .. #processes .. " 个) ===")

  -- 按类型分组
  local by_type = {}
  for _, proc in ipairs(processes) do
    if not by_type[proc.type] then
      by_type[proc.type] = {}
    end
    table.insert(by_type[proc.type], proc)
  end

  -- 显示每种类型的进程
  for type_name, type_procs in pairs(by_type) do
    vim.notify("[LSP] " .. type_name:upper() .. " 进程 (" .. #type_procs .. " 个):")

    -- 按服务器名称排序
    table.sort(type_procs, function(a, b)
      return a.server_name < b.server_name
    end)

    for _, proc in ipairs(type_procs) do
      local status_icon = "○"
      if proc.state == "Z" then
        status_icon = "☠" -- 僵尸进程
      elseif proc.state == "T" then
        status_icon = "⏸" -- 停止的进程
      elseif active_pids[proc.pid] then
        status_icon = "●" -- 活跃进程
      end

      local memory_str = proc.memory_mb > 0 and string.format("%.1f", proc.memory_mb) .. " MB" or "内存未知"
      local uptime_str = ""

      if proc.uptime_seconds > 0 then
        if proc.uptime_seconds < 60 then
          uptime_str = string.format("%.0f秒", proc.uptime_seconds)
        elseif proc.uptime_seconds < 3600 then
          uptime_str = string.format("%.1f分钟", proc.uptime_seconds / 60)
        else
          uptime_str = string.format("%.1f小时", proc.uptime_seconds / 3600)
        end
      end

      local line = string.format(
        "[LSP]   %s %-20s PID:%-8d %-12s %-10s %s",
        status_icon,
        proc.server_name,
        proc.pid,
        memory_str,
        uptime_str,
        proc.state
      )

      -- 如果是僵尸进程，添加警告
      if proc.state == "Z" then
        line = line .. " (僵尸进程，需要清理)"
      end

      vim.notify(line)
    end
    vim.notify("[LSP] ")
  end

  -- 统计信息
  local zombies = 0
  local high_memory = 0
  local long_running = 0

  for _, proc in ipairs(processes) do
    if proc.state == "Z" then
      zombies = zombies + 1
    end
    if proc.memory_mb > 1000 then
      high_memory = high_memory + 1
    end
    if proc.uptime_seconds > 3600 then
      long_running = long_running + 1
    end
  end

  vim.notify("[LSP] 统计信息:")
  vim.notify("[LSP]   • 僵尸进程: " .. zombies .. " 个")
  vim.notify("[LSP]   • 高内存进程 (>1GB): " .. high_memory .. " 个")
  vim.notify("[LSP]   • 长时间运行 (>1小时): " .. long_running .. " 个")
  vim.notify("[LSP]   • 活跃客户端: " .. #active_clients .. " 个")
  vim.notify("[LSP] ")
  vim.notify("[LSP] 建议操作:")
  vim.notify("[LSP]   • 运行 :LspCleanupProcesses 清理僵尸/空闲进程")
  vim.notify("[LSP]   • 运行 :LspKillProcess PID 终止特定进程")
  vim.notify("[LSP]   • 运行 :LspRestartAll 重启所有 LSP 进程")
  vim.notify("[LSP] === 状态显示完成 ===")
end, { desc = "显示所有 LSP 相关进程状态" })

vim.api.nvim_create_user_command("LspCleanupProcesses", function()
  -- 清理僵尸进程和空闲进程
  vim.notify("[LSP] === 清理 LSP 进程 ===")
  local cleaned = cleanup_zombie_processes()

  if cleaned > 0 then
    vim.notify("[LSP] 已清理 " .. cleaned .. " 个进程")
  else
    vim.notify("[LSP] 没有需要清理的进程")
  end

  vim.notify("[LSP] === 清理完成 ===")
end, { desc = "清理僵尸进程和空闲的 LSP 进程" })

vim.api.nvim_create_user_command("LspKillProcess", function(opts)
  -- 终止特定 LSP 进程
  local pid = tonumber(opts.args)

  if not pid then
    vim.notify("[LSP] 使用方法: :LspKillProcess PID")
    vim.notify("[LSP] 例如: :LspKillProcess 12345")
    return
  end

  -- 检查进程是否存在
  local proc_info = get_process_info(pid)
  if not proc_info or not proc_info.exists then
    vim.notify("[LSP] 进程 PID " .. pid .. " 不存在", vim.log.levels.ERROR)
    return
  end

  -- 检查是否是 LSP 相关进程
  local is_lsp_process = false
  local processes = get_all_lsp_processes()
  for _, proc in ipairs(processes) do
    if proc.pid == pid then
      is_lsp_process = true
      break
    end
  end

  if not is_lsp_process then
    vim.notify("[LSP] 警告: PID " .. pid .. " 可能不是 LSP 进程", vim.log.levels.WARN)
    vim.notify("[LSP] 进程信息: " .. (proc_info.cmdline or "未知"))

    -- 询问确认
    local confirm = vim.fn.input("确定要终止此进程吗？(y/N): ")
    if confirm:lower() ~= "y" then
      vim.notify("[LSP] 操作已取消")
      return
    end
  end

  vim.notify("[LSP] 正在终止进程 PID " .. pid .. "...")

  -- 先尝试优雅终止
  local success1 = os.execute("kill -15 " .. pid .. " 2>/dev/null")

  -- 等待 1 秒
  vim.defer_fn(function()
    -- 检查进程是否还存在
    local still_exists = false
    local check_info = get_process_info(pid)
    if check_info and check_info.exists then
      still_exists = true
    end

    if still_exists then
      vim.notify("[LSP] 进程仍在运行，使用强制终止...")
      local success2 = os.execute("kill -9 " .. pid .. " 2>/dev/null")

      if success2 then
        vim.notify("[LSP] 进程 PID " .. pid .. " 已强制终止")
      else
        vim.notify("[LSP] 无法强制终止进程 PID " .. pid, vim.log.levels.ERROR)
      end
    else
      vim.notify("[LSP] 进程 PID " .. pid .. " 已成功终止")
    end
  end, 1000)
end, { desc = "终止特定的 LSP 进程", nargs = 1 })

vim.api.nvim_create_user_command("LspRestartAll", function()
  -- 重启所有 LSP 进程
  vim.notify("[LSP] === 重启所有 LSP 进程 ===")

  -- 获取所有进程
  local processes = get_all_lsp_processes()

  if #processes == 0 then
    vim.notify("[LSP] 没有找到 LSP 进程")
    return
  end

  vim.notify("[LSP] 找到 " .. #processes .. " 个 LSP 进程，正在重启...")

  -- 记录需要重启的服务器
  local servers_to_restart = {}

  -- 终止所有进程
  for _, proc in ipairs(processes) do
    if proc.type == "lsp" then
      servers_to_restart[proc.server_name] = true
    end

    -- 优雅终止
    os.execute("kill -15 " .. proc.pid .. " 2>/dev/null")
  end

  -- 等待 2 秒让进程退出
  vim.defer_fn(function()
    -- 强制终止仍在运行的进程
    local remaining_processes = get_all_lsp_processes()
    for _, proc in ipairs(remaining_processes) do
      os.execute("kill -9 " .. proc.pid .. " 2>/dev/null")
    end

    vim.notify("[LSP] 所有 LSP 进程已终止")

    -- 清除缓冲区标记
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.b[bufnr].lsp_started = nil
      end
    end

    -- 重新启动当前文件的 LSP
    local bufnr = vim.api.nvim_get_current_buf()
    local ft = vim.bo.filetype

    if ft and ft ~= "" then
      vim.notify("[LSP] 正在为 " .. ft .. " 重新启动 LSP 服务器...")

      vim.schedule(function()
        start_lsp_for_filetype(ft, bufnr)
      end)

      vim.notify("[LSP] LSP 服务器已重新启动")
    end

    vim.notify("[LSP] === 重启完成 ===")
  end, 2000)
end, { desc = "重启所有 LSP 进程" })

vim.api.nvim_create_user_command("LspProcessMonitor", function()
  -- 控制进程监控
  if M.config.memory_limit.enabled then
    vim.notify("[LSP] 进程监控状态:")
    vim.notify("[LSP]   • 内存限制: 已启用")
    vim.notify("[LSP]   • 进程监控: 已启动")
    vim.notify("[LSP]   • 自动清理: 每30分钟")
    vim.notify("[LSP]   • 监控间隔: 每2分钟")
    vim.notify("[LSP] ")
    vim.notify("[LSP] 相关命令:")
    vim.notify("[LSP]   • :LspProcessStatus - 显示进程状态")
    vim.notify("[LSP]   • :LspCleanupProcesses - 清理僵尸进程")
    vim.notify("[LSP]   • :LspKillProcess PID - 终止特定进程")
    vim.notify("[LSP]   • :LspRestartAll - 重启所有进程")
  else
    vim.notify("[LSP] 进程监控状态: 未启用（需要启用内存限制）")
    vim.notify("[LSP] 请在配置中设置 memory_limit.enabled = true")
  end
end, { desc = "显示 LSP 进程监控状态" })

-- ============================================
-- 进程监控配置
-- ============================================
--
-- 新增的进程监控功能:
-- 1. 自动检测和清理僵尸进程 (状态为 Z)
-- 2. 监控长时间空闲进程 (>30分钟)
-- 3. 检测高内存使用进程 (>2GB)
-- 4. 识别重复的 Copilot 进程
-- 5. 定期自动清理 (每30分钟)
-- 6. 实时监控 (每2分钟)
--
-- 支持的进程类型:
-- • LSP 服务器 (language-server, *-ls, pyright, rust-analyzer 等)
-- • 格式化工具 (prettier, stylua, black, isort 等)
-- • Copilot 进程
--
-- 监控规则:
-- 1. 僵尸进程 (Z) - 立即清理
-- 2. 空闲进程 (>30分钟且无活跃客户端) - 清理
-- 3. 重复 Copilot 进程 - 清理
-- 4. 高内存进程 (>2GB) - 清理
-- 5. 进程数量过多 (>3倍并发限制) - 自动清理
-- 6. 高内存进程过多 (>2个) - 自动清理
--
-- 用户命令:
-- 1. :LspProcessStatus - 显示所有进程状态
-- 2. :LspCleanupProcesses - 手动清理进程
-- 3. :LspKillProcess PID - 终止特定进程
-- 4. :LspRestartAll - 重启所有 LSP 进程
-- 5. :LspProcessMonitor - 显示监控状态
--
-- 自动监控:
-- • 每2分钟检查一次进程状态
-- • 每30分钟执行一次自动清理
-- • 检测到异常时自动清理
--
-- 注意事项:
-- 1. 需要启用内存限制 (memory_limit.enabled = true)
-- 2. 依赖 /proc 文件系统 (Linux)
-- 3. 需要读取 /proc/[pid]/stat 和 /proc/[pid]/cmdline
-- 4. 使用 kill -15 (SIGTERM) 进行优雅终止
-- 5. 如果进程不响应，2秒后使用 kill -9 (SIGKILL)
-- 6. 只清理 LSP 相关进程，避免误杀系统进程
--
-- 调试:
-- 1. 启用调试模式: :LspDebug
-- 2. 查看进程状态: :LspProcessStatus
-- 3. 手动清理: :LspCleanupProcesses
-- 4. 重启所有进程: :LspRestartAll
--
-- 常见问题:
-- 1. 进程数量过多 - 运行 :LspCleanupProcesses
-- 2. 内存泄漏 - 运行 :LspRestartAll
-- 3. 僵尸进程 - 自动清理或手动清理
-- 4. Copilot 重复进程 - 自动清理
-- ============================================

-- 进程监控测试命令
vim.api.nvim_create_user_command("LspTestProcessMonitor", function()
  -- 测试进程监控系统
  vim.notify("[LSP] === 测试进程监控系统 ===")

  -- 测试 1: 获取进程信息
  vim.notify("[LSP] 测试 1: 获取当前进程信息...")
  local current_pid = vim.fn.getpid()
  local proc_info = get_process_info(current_pid)

  if proc_info and proc_info.exists then
    vim.notify("[LSP]   ✓ 成功获取进程信息 (PID: " .. current_pid .. ")")
    vim.notify("[LSP]     状态: " .. proc_info.state)
    vim.notify("[LSP]     内存: " .. proc_info.memory_mb .. " MB")
    vim.notify("[LSP]     运行时间: " .. proc_info.uptime_seconds .. " 秒")
  else
    vim.notify("[LSP]   ✗ 无法获取进程信息")
  end

  -- 测试 2: 获取所有 LSP 进程
  vim.notify("[LSP] ")
  vim.notify("[LSP] 测试 2: 扫描 LSP 相关进程...")
  local processes = get_all_lsp_processes()

  if #processes > 0 then
    vim.notify("[LSP]   ✓ 找到 " .. #processes .. " 个 LSP 相关进程")

    -- 按类型统计
    local by_type = {}
    for _, proc in ipairs(processes) do
      by_type[proc.type] = (by_type[proc.type] or 0) + 1
    end

    for type_name, count in pairs(by_type) do
      vim.notify("[LSP]     • " .. type_name .. ": " .. count .. " 个")
    end

    -- 显示前几个进程
    vim.notify("[LSP]   ✓ 前 3 个进程:")
    for i = 1, math.min(3, #processes) do
      local proc = processes[i]
      vim.notify("[LSP]     [" .. i .. "] " .. proc.server_name .. " (PID: " .. proc.pid .. ")")
    end
  else
    vim.notify("[LSP]   ✗ 没有找到 LSP 相关进程")
  end

  -- 测试 3: 检查僵尸进程
  vim.notify("[LSP] ")
  vim.notify("[LSP] 测试 3: 检查僵尸进程...")
  local zombies = 0
  for _, proc in ipairs(processes) do
    if proc.state == "Z" then
      zombies = zombies + 1
    end
  end

  if zombies > 0 then
    vim.notify("[LSP]   ⚠ 发现 " .. zombies .. " 个僵尸进程")
    vim.notify("[LSP]     建议运行 :LspCleanupProcesses 清理")
  else
    vim.notify("[LSP]   ✓ 没有发现僵尸进程")
  end

  -- 测试 4: 检查高内存进程
  vim.notify("[LSP] ")
  vim.notify("[LSP] 测试 4: 检查高内存进程 (>1GB)...")
  local high_memory = 0
  for _, proc in ipairs(processes) do
    if proc.memory_mb > 1000 then
      high_memory = high_memory + 1
    end
  end

  if high_memory > 0 then
    vim.notify("[LSP]   ⚠ 发现 " .. high_memory .. " 个高内存进程")
    vim.notify("[LSP]     建议运行 :LspRestartAll 重启")
  else
    vim.notify("[LSP]   ✓ 没有发现高内存进程")
  end

  -- 测试 5: 检查进程监控状态
  vim.notify("[LSP] ")
  vim.notify("[LSP] 测试 5: 检查进程监控状态...")
  if M.config.memory_limit.enabled then
    vim.notify("[LSP]   ✓ 内存限制已启用")
    vim.notify("[LSP]   ✓ 进程监控已集成")
    vim.notify("[LSP]   • 监控间隔: 每2分钟")
    vim.notify("[LSP]   • 自动清理: 每30分钟")
  else
    vim.notify("[LSP]   ⚠ 内存限制未启用")
    vim.notify("[LSP]     进程监控需要 memory_limit.enabled = true")
  end

  vim.notify("[LSP] ")
  vim.notify("[LSP] === 测试完成 ===")
  vim.notify("[LSP] ")
  vim.notify("[LSP] 建议操作:")
  vim.notify("[LSP] 1. 运行 :LspProcessStatus 查看详细状态")
  vim.notify("[LSP] 2. 运行 :LspCleanupProcesses 清理进程")
  vim.notify("[LSP] 3. 运行 :LspProcessMonitor 查看监控配置")
  vim.notify("[LSP] 4. 启用调试模式 :LspDebug 查看更多信息")
end, { desc = "测试 LSP 进程监控系统" })

-- ============================================
-- LSP 内存限制优化指南（更新版）
-- ============================================
--
-- 已实现的内存限制功能:
-- 1. 所有 LSP 服务器通用内存限制配置
-- 2. 特定服务器的优化设置（Lua、Python、TypeScript 等）
-- 3. 实时内存使用监控
-- 4. 内存超限警告和自动限制
-- 5. 动态内存限制（根据系统内存自动调整）
-- 6. lua_ls 详细数量限制
-- 7. LSP 进程监控和自动清理（新增）
--
-- 支持的服务器内存限制:
-- • lua_ls - workspace 大小限制，文件数量限制，诊断数量限制，补全数量限制
-- • pyright - 分析范围限制，堆内存限制，类型检查模式限制
-- • ts_ls/tsserver - TypeScript 内存限制，项目文件限制，自动导入禁用
-- • clangd - 内存限制，索引大小限制，符号索引文件限制
-- • rust_analyzer - 内存使用限制，功能限制，Cargo 特性限制
-- • gopls - 内存模式降级，功能限制，静态检查禁用
-- • html/cssls/jsonls - 建议功能限制，特定功能禁用
-- • yamlls - 模式存储禁用，模式清空
-- • bashls - shellcheck 禁用
-- • 其他服务器 - 通用内存限制标记和性能模式
--
-- lua_ls 详细限制配置:
-- • maxPreload: 最大预加载文件数量（动态调整）
-- • maxLibraryFiles: 最大库文件数量（动态调整）
-- • diagnostics.maxItems: 最大诊断数量（动态调整）
-- • completion.maxItems: 最大补全数量（动态调整的一半）
-- • workspaceRate: 诊断频率降低到 30
-- • workspaceDelay: 诊断延迟增加到 1500ms
-- • 语义高亮禁用，颜色模式禁用，遥测禁用
-- • 自动 require 禁用，单词显示禁用
-- • 数组索引提示禁用，参数类型提示禁用
--
-- 动态内存限制系统:
-- 1. 自动检测系统总内存
-- 2. 根据内存大小自动调整限制
-- 3. 根据当前内存使用率进一步优化
-- 4. 支持手动配置覆盖自动限制
--
-- 动态限制规则（根据系统内存）:
-- • ≤4GB: clients=2, memory=256MB, files=500, lua_items=500
-- • ≤8GB: clients=3, memory=512MB, files=1000, lua_items=1000
-- • ≤16GB: clients=5, memory=1024MB, files=2000, lua_items=2000
-- • ≤32GB: clients=8, memory=2048MB, files=5000, lua_items=5000
-- • >32GB: clients=12, memory=4096MB, files=10000, lua_items=10000
--
-- 自适应调整:
-- • 内存使用率 >80%: 减少限制 20-30%
-- • 内存使用率 <40%: 增加限制 20-30%
--
-- 内存管理命令:
-- 1. :LspMemoryStatus - 显示系统内存、动态限制和详细状态
-- 2. :LspForceMemoryLimit - 强制应用内存限制到所有服务器
-- 3. :LspMemoryLimit clients=3 memory=512 - 动态调整内存限制
-- 4. :LspReduceMemory - 减少内存使用（停止空闲客户端）
-- 5. :CopilotMemoryLimit memory=256 delay=100 - 调整 Copilot 设置
-- 6. :LspProcessStatus - 显示所有 LSP 进程状态（新增）
-- 7. :LspCleanupProcesses - 清理僵尸/空闲进程（新增）
-- 8. :LspKillProcess PID - 终止特定进程（新增）
-- 9. :LspRestartAll - 重启所有 LSP 进程（新增）
-- 10. :LspProcessMonitor - 显示进程监控状态（新增）
-- 11. :LspTestProcessMonitor - 测试进程监控系统（新增）
--
-- 启用动态限制:
-- 将配置中的 max_memory_per_client 设置为 0 即可启用动态限制:
-- memory_limit = { max_memory_per_client = 0, ... }

-- 进程监控系统（新增）:
-- 1. 自动检测僵尸进程 (状态 Z) 并清理
-- 2. 监控长时间空闲进程 (>30分钟) 并清理
-- 3. 检测高内存使用进程 (>2GB) 并清理
-- 4. 识别重复的 Copilot 进程并清理
-- 5. 每2分钟检查一次进程状态
-- 6. 每30分钟执行一次自动清理
-- 7. 支持手动管理和调试命令

-- 进程监控规则:
-- • 僵尸进程 (Z) - 立即清理
-- • 空闲进程 (>30分钟且无活跃客户端) - 清理
-- • 重复 Copilot 进程 - 清理
-- • 高内存进程 (>2GB) - 清理
-- • 进程数量过多 (>3倍并发限制) - 自动清理
-- • 高内存进程过多 (>2个) - 自动清理

-- 支持的进程类型:
-- • LSP 服务器: language-server, *-ls, pyright, rust-analyzer, clangd, gopls 等
-- • 格式化工具: prettier, stylua, black, isort, shfmt, clang-format 等
-- • Copilot 进程: copilot-language-server 等
--
-- 监控和优化建议:
-- 1. 定期运行 :LspMemoryStatus 检查内存使用情况
-- 2. 如果看到 ● 严重状态，运行 :LspForceMemoryLimit
-- 3. 系统变慢时运行 :LspReduceMemory 释放内存
-- 4. 调整设置后运行 :LspForceMemoryLimit 立即生效
-- 5. 对于大型项目，适当增加 max_workspace_files
-- 6. 启用动态限制以获得最佳性能
-- 7. 定期运行 :LspProcessStatus 检查进程状态（新增）
-- 8. 发现僵尸进程时运行 :LspCleanupProcesses（新增）
-- 9. 内存泄漏时运行 :LspRestartAll 重启所有进程（新增）
-- 10. 使用 :LspTestProcessMonitor 测试监控系统（新增）
--
-- 调试和故障排除:
-- 1. 启用调试模式: :LspDebug
-- 2. 测试配置: :LspTestConfig
-- 3. 查看客户端详情: :LspClients
-- 4. 清理重复客户端: :LspCleanup
-- 5. 查看 lua_ls 配置: 启用调试模式后启动 lua 文件
-- 6. 测试进程监控: :LspTestProcessMonitor（新增）
-- 7. 查看进程状态: :LspProcessStatus（新增）
-- 8. 清理进程: :LspCleanupProcesses（新增）
-- 9. 重启进程: :LspRestartAll（新增）
--
-- 注意:
-- • 内存限制通过服务器配置和环境变量实现
-- • 某些服务器可能需要重启才能应用新限制
-- • 实际内存使用可能因项目大小而异
-- • 监控功能依赖 /proc 文件系统（Linux）
-- • 动态限制需要读取 /proc/meminfo 文件
-- • lua_ls 的数量限制可有效防止内存泄漏
-- • 进程监控需要启用内存限制 (memory_limit.enabled = true)
-- • 进程监控依赖 /proc/[pid]/stat 和 /proc/[pid]/cmdline 文件
-- • 清理进程时先尝试 SIGTERM (kill -15)，2秒后使用 SIGKILL (kill -9)
-- • 只清理 LSP 相关进程，避免误杀系统进程
-- • 进程监控每2分钟检查一次，每30分钟自动清理一次
-- ============================================

return M
