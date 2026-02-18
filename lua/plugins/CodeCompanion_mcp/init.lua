-- CodeCompanion MCP 集成插件配置
-- 文件：~/.config/nvim/lua/plugins/CodeCompanion_mcp/init.lua
-- 使用模块化配置

return {
  "olimorris/codecompanion.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "hrsh7th/nvim-cmp",
    "nvim-telescope/telescope.nvim",
    "stevearc/dressing.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown", "codecompanion" }
    },
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
    local plugin_dir = "/root/.config/nvim/lua/plugins/CodeCompanion_mcp/"
    
    -- 添加目录到包路径（使用绝对路径）
    package.path = package.path .. ";" .. plugin_dir .. "lua/?.lua"
    package.path = package.path .. ";" .. plugin_dir .. "lua/?/init.lua"
    
    -- 同时添加原始目录作为备用
    package.path = package.path .. ";" .. plugin_dir .. "core/?.lua"
    package.path = package.path .. ";" .. plugin_dir .. "config/?.lua"
    package.path = package.path .. ";" .. plugin_dir .. "mcp/?.lua"
    package.path = package.path .. ";" .. plugin_dir .. "extensions/?.lua"

    -- 导入各个模块的配置
    local adapters = require("core.adapters")
    local interactions_with_mcp = require("mcp.interactions_with_mcp")
    local display = require("core.display")
    local mcphub_integration = require("config.mcphub_integration")

    -- 获取 MCP Hub 完整配置
    local mcphub_config = mcphub_integration.get_full_config()

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

      -- ==================== MCP Hub 扩展配置 ====================
      extensions = mcphub_config.extension,

      opts = {
        language = "Chinese",
        mcphub = mcphub_config,
      },
    }

    return config
  end,
  config = function(_, opts)
    -- 设置包路径，确保模块可以正确加载
    local plugin_dir = "/root/.config/nvim/lua/plugins/CodeCompanion_mcp/"
    
    -- 添加目录到包路径（使用绝对路径）
    package.path = package.path .. ";" .. plugin_dir .. "lua/?.lua"
    package.path = package.path .. ";" .. plugin_dir .. "lua/?/init.lua"
    
    -- 同时添加原始目录作为备用
    package.path = package.path .. ";" .. plugin_dir .. "core/?.lua"
    package.path = package.path .. ";" .. plugin_dir .. "config/?.lua"
    package.path = package.path .. ";" .. plugin_dir .. "mcp/?.lua"
    package.path = package.path .. ";" .. plugin_dir .. "extensions/?.lua"

    -- 导入配置模块
    local config_module = require("config.config")

    -- 调用配置模块的 setup 函数
    config_module.setup(opts)
  end,
}
