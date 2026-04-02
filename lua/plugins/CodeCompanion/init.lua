-- CodeCompanion MCP 集成插件配置
-- 文件：~/.config/nvim/lua/plugins/CodeCompanion/init.lua

return {
  "olimorris/codecompanion.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "hrsh7th/nvim-cmp",
    "stevearc/dressing.nvim",
    -- MCP Hub 插件
    {
      "ravitemer/mcphub.nvim",
      dependencies = {
        "nvim-lua/plenary.nvim",
      },
      build = "npm install -g mcp-hub@latest",
    },
  },
  opts = function()
    -- 首先设置包路径，确保模块可以正确加载
    -- 导入各个模块的配置
    local adapters = require("plugins.CodeCompanion.core.adapters")
    local interactions_with_mcp = require("plugins.CodeCompanion.mcp.interactions_with_mcp")
    local display = require("plugins.CodeCompanion.core.display")
    
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

    return config
  end,
  config = function(_, opts)
    -- 导入配置模块
    local config_module = require("plugins.CodeCompanion.config.config")

    -- 调用配置模块的 setup 函数
    config_module.setup(opts)
  end,
}
