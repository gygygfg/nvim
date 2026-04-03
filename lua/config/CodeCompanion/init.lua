-- CodeCompanion MCP 集成插件配置
-- 使用 vim.pack.add() 安装插件
-- 文件：/root/nvim/lua/config/CodeCompanion/init.lua

-- 插件配置函数
local function setup_codecompanion()
  -- 导入各个模块的配置
  local adapters = require("config.CodeCompanion.core.adapters")
  local interactions_with_mcp = require("config.CodeCompanion.mcp.interactions_with_mcp")
  local display = require("config.CodeCompanion.core.display")

  -- 构建配置表
  local config = {
    -- ==================== 日志配置 ====================
    log_level = "DEBUG", -- TRACE > DEBUG > INFO > ERROR

    -- ==================== 适配器配置 ====================
    adapters = adapters.config,

    -- ==================== 交互策略配置 ====================
    interactions = interactions_with_mcp.config,

    -- ==================== 显示配置 ====================
    display = display.config,

    -- ==================== 语言配置 ====================
    opts = {
      language = "Chinese",
    },
  }

  -- 导入配置模块
  local config_module = require("config.CodeCompanion.config.config")

  -- 调用配置模块的 setup 函数
  config_module.setup(config)
end

-- 运行 mcphub 构建命令
local function run_mcphub_build()
  -- 检查 mcphub 是否已安装
  local success, _ = pcall(require, "mcphub")
  if not success then
    vim.notify("正在安装 MCP Hub 依赖...", vim.log.levels.INFO)

    -- 运行构建命令
    local handle = io.popen("npm install -g mcp-hub@latest 2>&1")
    local result = handle:read("*a")
    handle:close()

    if result:match("ERROR") or result:match("error") then
      vim.notify("MCP Hub 安装失败: " .. result, vim.log.levels.ERROR)
    else
      vim.notify("MCP Hub 安装成功", vim.log.levels.INFO)
    end
  end
end

-- 使用 vim.pack.add() 安装所有依赖插件
local function install_plugins()
  -- 安装所有插件（使用完整的 GitHub URL）
  vim.pack.add({
    { src = "https://github.com/olimorris/codecompanion.nvim" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
    { src = "https://github.com/hrsh7th/nvim-cmp" },
    { src = "https://github.com/stevearc/dressing.nvim" },
    { src = "https://github.com/ravitemer/mcphub.nvim" },
  })

  -- 运行 mcphub 构建命令
  vim.defer_fn(function()
    run_mcphub_build()
  end, 2000)

  vim.notify("CodeCompanion 插件已通过 vim.pack.add() 安装", vim.log.levels.INFO)
end

-- 主初始化函数
local function init()
  -- 安装插件
  install_plugins()

  -- 延迟设置插件配置，确保插件已加载
  vim.defer_fn(function()
    -- 检查主插件是否已加载
    local success, codecompanion = pcall(require, "codecompanion")
    if success then
      -- 设置插件配置
      setup_codecompanion()
      vim.notify("CodeCompanion 配置已加载", vim.log.levels.INFO)
    else
      vim.notify("CodeCompanion 插件未找到，请确保插件已安装", vim.log.levels.WARN)
    end
  end, 1000)
end

-- 延迟初始化，确保插件已加载
vim.defer_fn(function()
  init()
end, 100)

return {
  setup = setup_codecompanion,
  init = init,
  install_plugins = install_plugins,
}
