-- MCP 工具配置文件 - 优化版本
-- 避免重复定义基础工具，专注于 MCP 特有功能

local M = {}

-- ==================== MCP 服务器配置 ====================
M.servers = {
  context7 = {
    enabled = true,
    command = "/root/.config/nvim/mcp/wrappers/nvm-wrapper.sh",
    args = {"npx", "-y", "@upstash/context7-mcp", "--api-key", "ctx7sk-be72ace2-0150-4385-acef-8d0596dfff07"},
    autoApprove = true,
    priority = 1,
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
    command = "python3",
    args = {"/root/.config/nvim/lua/plugins/CodeCompanion_mcp/mcp/crawl4ai/mcp_server_with_api.py"},
    env = {
      CRAWL4AI_BASE_URL = "http://localhost:11235",
      CRAWL4AI_API_KEY = "my_local_token_12345",
    },
    autoApprove = true,
    priority = 2,
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
    command = "/root/.config/nvim/mcp/wrappers/nvm-wrapper.sh",
    args = {"npx", "mcp-neovim-server"},
    autoApprove = true,
    priority = 3,
    description = "Neovim 编辑器操作服务",
  },

  github = {
    enabled = true,
    command = "/root/.config/nvim/mcp/wrappers/nvm-wrapper.sh",
    args = {"npx", "@modelcontextprotocol/server-github"},
    env = { GITHUB_TOKEN = "cmd:echo $GITHUB_TOKEN" },
    autoApprove = true,
    priority = 4,
    description = "GitHub 仓库管理服务",
  },

  filesystem = {
    enabled = true,
    command = "/root/.config/nvim/mcp/wrappers/nvm-wrapper.sh",
    args = {"npx", "@modelcontextprotocol/server-filesystem"},
    autoApprove = true,
    priority = 5,
    description = "文件系统操作服务",
  }
}

-- ==================== MCP 特有工具定义 ====================
-- 只定义 MCP 特有的工具，避免重复基础工具
M.tools = {}

-- 为每个 MCP 服务器创建工具定义
for server_name, server_config in pairs(M.servers) do
  if server_config.enabled then
    M.tools[server_name] = {
      description = server_config.description or "MCP 服务器工具",
      desc = server_config.description or "MCP 服务器工具",
      callback = "plugins.CodeCompanion_mcp.extensions.custom_mcp_tools",
      opts = {
        require_approval_before = false,
        auto_trigger = true,
        priority = server_config.priority or 5,
        keywords = server_config.auto_trigger_keywords or {},
      },
    }
  end
end

-- 添加特定的 MCP 工具变体
M.tools["context7_search"] = {
  description = "Context7 文档搜索工具",
  desc = "Context7 文档搜索工具",
  callback = "plugins.CodeCompanion_mcp.extensions.custom_mcp_tools",
  opts = {
    require_approval_before = false,
    auto_trigger = true,
    priority = 1,
    keywords = {"search", "find", "lookup", "query", "documentation"},
  },
}

-- 注意：MCP Hub 工具（mcphub__get_current_servers, mcphub__toggle_mcp_server）
-- 已由 MCP Hub 扩展自动提供，无需在此重复定义

-- ==================== MCP 特有工具组定义 ====================
-- 只定义 MCP 特有的工具组，避免重复基础工具组
M.groups = {
  ["mcp_web_tools"] = {
    description = "MCP 网页相关工具组",
    prompt = "我正在给你访问 MCP 网页相关工具的权限，包括文档搜索和网页爬取",
    tools = {
      "crawl4ai",
      "context7_search",
    },
    opts = {
      collapse_tools = false,
      require_approval_for_group = false,
    },
  },

  ["mcp_server_management"] = {
    description = "MCP 服务器管理工具组",
    prompt = "我正在给你访问 MCP 服务器管理工具的权限，可以查看和管理服务器状态",
    tools = {
      "mcphub__get_current_servers",  -- 由 MCP Hub 扩展提供
      "mcphub__toggle_mcp_server",    -- 由 MCP Hub 扩展提供
    },
    opts = {
      collapse_tools = false,
      require_approval_for_group = false,
    },
  },
}

-- ==================== MCP 特有默认工具 ====================
-- 只添加 MCP 特有的默认工具
M.default_tools = {
  -- "context7",           -- 文档查询工具
  -- "crawl4ai",          -- 网页爬取工具
  "mcphub", -- 服务器状态查询（由 MCP Hub 扩展提供）
}

-- ==================== 精简系统提示配置 ====================
-- 只包含 MCP 特有的提示信息
M.system_prompt = [[## MCP 服务器
可用的 MCP 服务器包括：
- @{context7}: 文档查询
- @{crawl4ai}: 网页爬取
- @{neovim}: 编辑器操作
- @{github}: GitHub 管理
- @{filesystem}: 文件系统操作

## MCP 使用指南
1. MCP Hub 扩展已自动提供服务器管理工具：
- @{mcphub__get_current_servers}: 获取当前 MCP 服务器状态
- @{mcphub__toggle_mcp_server}: 启动或停止 MCP 服务器
2. 直接调用具体的 MCP 服务器工具（如 @{context7}、@{crawl4ai} 等）
3. 需要确认的操作会询问许可
4. 执行结果会自动反馈]]

-- ==================== 导出函数 ====================
function M.get_tools_config()
  return {
    tools = M.tools,
    groups = M.groups,
    default_tools = M.default_tools,
    system_prompt = M.system_prompt,
  }
end

function M.get_servers_config()
  return M.servers
end

function M.get_groups_config()
  return M.groups
end

return M
