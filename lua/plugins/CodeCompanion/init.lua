-- CodeCompanion MCP 集成插件配置
-- 使用 load.addPack() 安装插件
-- 文件：/root/nvim/lua/plugins/CodeCompanion/init.lua

vim.pack.add({
  -- 安装所有插件（使用完整的 GitHub URL）
  gh("hrsh7th/nvim-cmp"),
  gh("ravitemer/mcphub.nvim"),
  gh("nvim-lua/plenary.nvim"),
  gh("stevearc/dressing.nvim"),
  gh("olimorris/codecompanion.nvim"),
  gh("nvim-treesitter/nvim-treesitter"),
})

-- 预热 MCP Hub 依赖：检测 mcp-hub CLI，缺失则异步安装（不阻塞启动）
require("plugins.CodeCompanion.core.mcphub_bootstrap").ensure()

-- 延迟加载 CodeCompanion 及其配置
vim.defer_fn(function()
  -- 确保 opt 插件被加载
  vim.cmd("packadd codecompanion.nvim")

  local ok, codecompanion = pcall(require, "codecompanion")
  if not ok then
    vim.notify("⚠️  CodeCompanion plugin not found", vim.log.levels.ERROR)
    return
  end

  -- 导入各个模块的配置
  local adapters = require("plugins.CodeCompanion.core.adapters")
  local interactions_with_mcp = require("plugins.CodeCompanion.mcp.interactions_with_mcp")
  local display = require("plugins.CodeCompanion.core.display")
  local mcp = require("plugins.CodeCompanion.mcp.mcp")

  -- 构建配置表
  local config = {
    -- ==================== 日志配置 ====================
    log_level = "DEBUG", -- TRACE > DEBUG > INFO > ERROR

    -- ==================== 适配器配置 ====================
    adapters = adapters.config,

    -- ==================== 交互策略配置 ====================
    interactions = interactions_with_mcp.config,

    -- ==================== MCP 服务器配置 ====================
    mcp = {
      servers = mcp.servers,
      opts = {
        default_servers = {}, -- 自动启动并添加到聊天的服务器名称列表
        acp_enabled = true, -- 为 ACP 适配器启用 MCP 服务器？
        timeout = 30e3, -- MCP 服务器响应超时时间（毫秒）
      },
    },

    -- ==================== 显示配置 ====================
    display = display.config,

    -- ==================== 语言配置 ====================
    opts = {
      language = "Chinese",
    },
  }

  -- 导入配置模块（使用直接 require 以获取返回值）
  local config_module = require("plugins.CodeCompanion.config.config")
  config_module.setup(config)
end, 100)
