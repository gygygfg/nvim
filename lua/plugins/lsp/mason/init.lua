-- Mason 简化初始化配置
-- 避免在插件加载时检查包可用性

local M = {}

local function custom_notify(msg, level)
  level = level or vim.log.levels.INFO
  local opts = {
    title = "Mason",
    timeout = 3000,
  }
  vim.notify(msg, level, opts)
end

-- 简化的包名映射
local PACKAGE_MAPPING = {
  bashls = "bash-language-server",
  biome = "biome",
  eslint = "eslint-lsp",
  gopls = "gopls",
  html = "html-lsp",
  pyright = "pyright",
  taplo = "taplo",
  ts_ls = "typescript-language-server",
  vimls = "vim-language-server",
  vtsls = "vtsls",
  yamlls = "yaml-language-server",
}

-- 获取包名
local function get_package_name(config_name)
  return PACKAGE_MAPPING[config_name] or config_name
end

-- 扫描配置目录
local function scan_config_directory(dir_type)
  local config_dir = vim.fn.stdpath("config") .. "/lua/plugins/lsp/mason/" .. dir_type
  local configs = {}

  if vim.fn.isdirectory(config_dir) == 0 then
    return configs
  end

  local files = vim.fn.glob(config_dir .. "/*.lua", true, true)
  for _, file in ipairs(files) do
    local name = file:match("([^/]+)%.lua$")
    if name then
      table.insert(configs, name)
    end
  end

  return configs
end

-- 主设置函数
function M.setup()
  -- 1. 设置 Mason 基础配置
  require("mason").setup({
    ui = {
      border = "rounded",
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗"
      },
    },
    log_level = vim.log.levels.INFO,
    max_concurrent_installers = 4,
  })

  -- 2. 设置 Mason LSP 配置（延迟加载）
  vim.defer_fn(function()
    local lsp_configs = scan_config_directory("lsp")

    -- mason-lspconfig 需要的是 LSP 服务器名称，不是 Mason 包名
    require("mason-lspconfig").setup({
      ensure_installed = lsp_configs, -- 直接使用配置文件名（如 bashls, html）
      automatic_installation = true,
    })

    custom_notify("📦 Mason LSP 配置完成: " .. #lsp_configs .. " 个服务器", vim.log.levels.INFO)
  end, 1000)

  -- 3. 延迟加载 LSP 配置
  vim.defer_fn(function()
    local lsp_loader = require("plugins.lsp.mason.lsp_config_loader")
    local loaded_servers = lsp_loader.setup_all_lsp_servers()

    -- custom_notify("🚀 LSP 服务器加载完成: " .. #loaded_servers .. " 个服务器", vim.log.levels.INFO)
  end, 2000)

  -- custom_notify("✅ Mason 初始化完成", vim.log.levels.INFO)

  return {
    get_package_name = get_package_name,
    scan_configs = function(dir_type)
      return scan_config_directory(dir_type)
    end
  }
end

return M
