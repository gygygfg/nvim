-- LSP 配置加载器
-- 从新的 Mason 目录结构加载 LSP 配置

local M = {}

local function custom_notify(msg, level)
  level = level or vim.log.levels.INFO
  local opts = {
    title = "LSP 加载器",
    timeout = 3000,
  }
  vim.notify(msg, level, opts)
end

-- 扫描 LSP 配置目录
function M.scan_lsp_configs()
  local config_dir = vim.fn.stdpath("config") .. "/lua/plugins/lsp/mason/lsp"
  local configs = {}

  if vim.fn.isdirectory(config_dir) == 0 then
    custom_notify("❌ LSP 配置目录不存在: " .. config_dir, vim.log.levels.ERROR)
    return configs
  end

  local ok, iter, state = pcall(vim.loop.fs_scandir, config_dir)
  if not ok then
    custom_notify("❌ 无法扫描目录: " .. config_dir, vim.log.levels.ERROR)
    return configs
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(iter, state)
    if not name then break end

    if name:match("%.lua$") then
      local config_name = name:gsub("%.lua$", "")
      table.insert(configs, config_name)
    end
  end

  return configs
end

-- 加载单个 LSP 配置
function M.load_lsp_config(server_name)
  local ok, config = pcall(require, "plugins/lsp/mason/lsp/" .. server_name)

  if not ok then
    custom_notify("❌ 无法加载 LSP 配置: " .. server_name, vim.log.levels.ERROR)
    return nil
  end

  if type(config) ~= "table" then
    custom_notify("⚠️ LSP 配置格式错误: " .. server_name, vim.log.levels.WARN)
    return nil
  end

  return config
end

-- 设置所有 LSP 服务器
function M.setup_all_lsp_servers()
  local capabilities = require("cmp_nvim_lsp").default_capabilities()

  local all_servers = M.scan_lsp_configs()

  if #all_servers == 0 then
    custom_notify("⚠️ 没有找到 LSP 配置", vim.log.levels.WARN)
    return {}
  end

  custom_notify("🔄 开始加载 " .. #all_servers .. " 个 LSP 服务器", vim.log.levels.INFO)

  local loaded_servers = {}

  for _, server_name in ipairs(all_servers) do
    local config = M.load_lsp_config(server_name)

    if config then
      -- 确保配置有基本字段
      local server_config = vim.tbl_deep_extend("force", {
        capabilities = capabilities,
        on_attach = require('keymaps').mason()
      }, config)

      -- 使用新的 vim.lsp.config API 设置 LSP 服务器
      local ok, _ = pcall(function()
        vim.lsp.config.add({
          name = server_name,
          config = server_config
        })
      end)

      if ok then
        table.insert(loaded_servers, server_name)
        custom_notify("✅ 已加载服务器: " .. server_name, vim.log.levels.INFO)
      else
        custom_notify("⚠️ 无法加载 LSP 服务器: " .. server_name, vim.log.levels.WARN)
      end
    end
  end

  -- custom_notify("🚀 LSP 服务器加载完成: " .. #loaded_servers .. "/" .. #all_servers, vim.log.levels.INFO)

  return loaded_servers
end

-- 获取服务器状态
function M.get_server_status(server_name)
  -- 检查是否已安装
  local registry = require("mason-registry")

  -- 首先尝试直接使用服务器名称
  local pkg = registry.get_package(server_name)

  -- 如果找不到，尝试使用包名映射
  if not pkg then
    local package_mapping = {
      bashls = "bash-language-server",
      biome = "biome",
      eslint = "eslint-lsp",
      gopls = "golangci-lint-lsp",
      html = "html-lsp",
      pyright = "pyright",
      taplo = "taplo",
      ts_ls = "typescript-language-server",
      vimls = "vim-language-server",
      vtsls = "vtsls",
      yamlls = "yaml-language-server",
    }

    local package_name = package_mapping[server_name]
    if package_name then
      pkg = registry.get_package(package_name)
    end
  end

  local installed = pkg and pkg:is_installed() or false

  -- 检查是否正在运行
  local running = false
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    if client.name == server_name then
      running = true
      break
    end
  end

  return {
    installed = installed,
    running = running,
    name = server_name,
    package = pkg and pkg.name or nil
  }
end

-- 获取所有服务器状态
function M.get_all_servers_status()
  local all_servers = M.scan_lsp_configs()
  local status = {}

  for _, server_name in ipairs(all_servers) do
    status[server_name] = M.get_server_status(server_name)
  end

  return status
end

-- 安装缺失的服务器
function M.install_missing_servers()
  local all_servers = M.scan_lsp_configs()
  local to_install = {}

  local registry = require("mason-registry")

  for _, server_name in ipairs(all_servers) do
    local pkg = registry.get_package(server_name)
    if pkg and not pkg:is_installed() then
      table.insert(to_install, server_name)
    end
  end

  if #to_install > 0 then
    custom_notify("📦 开始安装 " .. #to_install .. " 个缺失的 LSP 服务器", vim.log.levels.INFO)

    for _, server_name in ipairs(to_install) do
      local pkg = registry.get_package(server_name)
      if pkg then
        pkg:install()
      end
    end

    return to_install
  else
    custom_notify("✅ 所有 LSP 服务器都已安装", vim.log.levels.INFO)
    return {}
  end
end

return M

