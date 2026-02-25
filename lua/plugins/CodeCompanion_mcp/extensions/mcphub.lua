-- CodeCompanion MCP Hub 扩展模块
-- 文件: extensions/mcphub.lua
-- 根据 MCP Hub 集成文档创建

local M = {}

-- 扩展配置函数
function M.setup(opts)
  -- 定义 MCP 服务器配置
  local servers = {
    context7 = {
      enabled = true,
      priority = 1, -- 高优先级，用于代码文档查询
      description = "Context7 代码库文档服务",
      auto_trigger_keywords = {
        "documentation", "docs", "API", "library", "framework", "package",
        "npm", "pip", "install", "tutorial", "guide", "example",
        "sample", "code snippet", "how to use", "how to implement",
        "best practices", "getting started", "introduction"
      },
    },

    crawl4ai = {
      enabled = true,
      priority = 2, -- 中等优先级，用于网页内容查询
      description = "Crawl4AI 网页爬取服务",
      auto_trigger_keywords = {
        "crawl", "scrape", "extract", "webpage", "website", "article",
        "blog", "news", "content", "latest", "recent", "update",
        "get content from", "fetch from", "read from", "check website",
        "visit page", "http://", "https://", "www.", ".com", ".org"
      },
    },

    neovim = {
      enabled = true,
      priority = 3,
      description = "Neovim 编辑器操作服务",
    },

    github = {
      enabled = true,
      priority = 4,
      description = "GitHub 仓库管理服务",
    },
  }

  -- 返回扩展配置
  return {
    enabled = true,
    servers = servers,
    opts = {
      auto_approve = true,
      config_dir = vim.fn.expand("~/.config/nvim/mcp"),

      -- MCP 工具配置
      make_tools = true, -- 创建单个工具 (@server__tool) 和服务器组 (@server)
      show_server_tools_in_chat = true, -- 在聊天补全中显示单个工具
      add_mcp_prefix_to_tool_names = false, -- 是否添加 mcp__ 前缀
      show_result_in_chat = true, -- 在聊天缓冲区直接显示工具结果

      -- MCP 资源配置
      make_vars = true, -- 将 MCP 资源转换为 #variables

      -- MCP 提示配置
      make_slash_commands = true, -- 将 MCP 提示添加为 /slash 命令

      -- 自动调用配置
      auto_detect_mcp_usage = true, -- 自动检测是否需要使用 MCP
      auto_suggest_mcp_tools = true, -- 自动建议相关的 MCP 工具

      -- 结果处理配置
      format_mcp_results = true, -- 格式化 MCP 工具返回的结果
      show_mcp_tool_details = true, -- 显示 MCP 工具的详细信息
    }
  }
end

return M
