-- CodeCompanion MCP 集成插件配置
-- 使用 load.addPack() 安装插件
-- 文件：/root/nvim/lua/config/CodeCompanion/init.lua

local function run_mcphub_build()
  -- 检查 mcphub 是否已安装
  local success, _ = pcall(load.require, "mcphub")
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

load.addPack({
  -- 安装所有插件（使用完整的 GitHub URL）
  { src = "https://github.com/olimorris/codecompanion.nvim" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  { src = "https://github.com/hrsh7th/nvim-cmp" },
  { src = "https://github.com/stevearc/dressing.nvim" },
  { src = "https://github.com/ravitemer/mcphub.nvim" },
})

-- 运行 mcphub 构建命令
run_mcphub_build()

-- 延迟加载 CodeCompanion 及其配置
load.defer_fn(function()
  -- 确保 opt 插件被加载
  vim.cmd('packadd codecompanion.nvim')
  
  local ok, codecompanion = pcall(require, "codecompanion")
  if not ok then
    vim.notify("⚠️  CodeCompanion plugin not found", vim.log.levels.ERROR)
    return
  end

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

  -- 导入配置模块（使用直接 require 以获取返回值）
  local config_module = require("config.CodeCompanion.config.config")
  config_module.setup(config)
end, 100)
