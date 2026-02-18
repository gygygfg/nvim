-- ~/.config/nvim/lua/plugins/lsp/mason_setup.lua
local function custom_notify(msg, level)
  level = level or vim.log.levels.INFO
  local opts = {
    title = "Mason",
    timeout = 3000,
  }
  vim.notify(msg, level, opts)
end

local log_levels = vim.log.levels

-- ======================
-- 1. 初始化 Mason & Mason-LSPConfig
-- ======================
local mason = require("mason")
local mason_lspconfig = require("mason-lspconfig")

mason.setup({
  ui = {
    border = "rounded",
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗"
    },
  },
  -- 关键修复：配置 Mason 使用自定义通知
  log_level = vim.log.levels.INFO,
  max_concurrent_installers = 4,
})

-- 设置 Mason 的通知处理器
local mason_log = require("mason-core.log")
mason_log.notify = custom_notify

-- ======================
-- 2. 扫描servers目录获取服务列表
-- ======================
local function scan_servers_directory()
  local servers_path = vim.fn.stdpath("config") .. "/lua/plugins/lsp/servers"
  local servers = {}

  if vim.fn.isdirectory(servers_path) == 0 then
    custom_notify("❌ servers 目录不存在: " .. servers_path, log_levels.ERROR)
    return servers
  end

  local ok, iter, state = pcall(vim.loop.fs_scandir, servers_path)
  if not ok then
    custom_notify("❌ 无法扫描 servers 目录: " .. servers_path, log_levels.ERROR)
    return servers
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(iter, state)
    if not name then break end

    if name:match("%.lua$") then
      local server_name = name:gsub("%.lua$", "")
      table.insert(servers, server_name)
    end
  end

  return servers
end

local all_servers = scan_servers_directory()

mason_lspconfig.setup({
  ensure_installed = all_servers,
  automatic_installation = true,
})

-- ======================
-- 3. 监听 Mason 安装事件
-- ======================
local function setup_mason_handlers()
  local registry = require("mason-registry")
  
  -- 监听包安装状态变化
  registry:on("package:install:success", function(pkg)
    custom_notify("✅ " .. pkg.name .. " 安装成功", log_levels.INFO)
  end)

  registry:on("package:install:failed", function(pkg)
    custom_notify("❌ " .. pkg.name .. " 安装失败", log_levels.ERROR)
  end)

  registry:on("package:install:start", function(pkg)
    custom_notify("🔄 开始安装 " .. pkg.name, log_levels.INFO)
  end)
end

-- ======================
-- 4. 配置 LSP 服务器
-- ======================
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local function load_lsp_servers()
  local lspconfig = require("lspconfig")

  for _, server_name in ipairs(all_servers) do
    local ok, custom_config = pcall(require, "plugins/lsp/servers/" .. server_name)

    local server_config = {
      capabilities = capabilities,
      on_attach = require('keymaps').mason()
    }

    if ok and type(custom_config) == "table" then
      server_config = vim.tbl_deep_extend("force", server_config, custom_config)
    end

    -- Special handling for pyright to allow more dynamic configuration
    if server_name == "pyright" then
      -- We'll use a custom setup for pyright to handle dynamic environments
      local pyright_config = vim.tbl_deep_extend("force", {}, server_config)
      lspconfig[server_name].setup(pyright_config)
    elseif lspconfig[server_name] then
      lspconfig[server_name].setup(server_config)
      custom_notify("✅ 已加载服务器: " .. server_name, log_levels.INFO)
    else
      custom_notify("⚠️ 未知的 LSP 服务器: " .. server_name, log_levels.WARN)
    end
  end
end

-- ======================
-- 5. 启动 LSP
-- ======================
return {
  setup = function()
    -- 设置 Mason 事件处理器
    setup_mason_handlers()
    
    -- 加载所有 LSP 配置
    load_lsp_servers()
    
    -- 检查并安装缺失的包
    local registry = require("mason-registry")
    local to_install = {}
    
    for _, server in ipairs(all_servers) do
      local pkg = registry.get_package(server)
      if pkg and not pkg:is_installed() then
        table.insert(to_install, server)
      end
    end
    
    if #to_install > 0 then
      custom_notify("📦 开始自动安装 " .. #to_install .. " 个 LSP 服务器", log_levels.INFO)
    end
    
    custom_notify("🚀 LSP 配置已加载，找到 " .. #all_servers .. " 个服务器配置", log_levels.INFO)
  end,

  get_servers = function() return all_servers end,
}
