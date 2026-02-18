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

-- MCP 服务器智能选择工具
M.tools["mcp_servers"] = {
  description = "MCP 服务器工具组 - 智能自动选择最合适的 MCP 服务器",
  desc = "MCP 服务器工具组 - 智能自动选择最合适的 MCP 服务器",
  callback = "plugins.CodeCompanion_mcp.extensions.custom_mcp_tools",
  opts = {
    require_approval_before = false,
    auto_trigger = true,
    priority = 0, -- 最高优先级
    keywords = {
      "mcp", "server", "external", "service", "工具", "服务器", "外部", "服务"
    },
  },
}

-- ==================== MCP 特有工具组定义 ====================
-- 只定义 MCP 特有的工具组，避免重复基础工具组
M.groups = {
  ["mcp_servers"] = {
    description = "MCP 服务器工具组 - 自动选择最合适的 MCP 服务器处理任务",
    prompt = "我正在给你访问 MCP 服务器工具组的权限，可以智能选择最合适的工具处理您的需求",
    tools = {
      "context7",
      "crawl4ai",
      "neovim",
      "github",
      "filesystem",
      "context7_search",
      "mcp_servers",
    },
    opts = {
      collapse_tools = true,
      require_approval_for_group = false,
      auto_select = true,
      selection_logic = "intelligent",
      auto_trigger_keywords = {
        -- 通用 MCP 关键词
        "mcp", "server", "external", "service", "api",
        "工具", "服务器", "外部", "服务", "接口",

        -- 文档相关
        "documentation", "docs", "API", "library", "framework", "package",
        "文档", "说明书", "接口文档", "库", "框架", "包",

        -- 网页相关
        "crawl", "scrape", "extract", "webpage", "website", "article",
        "爬取", "抓取", "提取", "网页", "网站", "文章",

        -- 编辑器相关
        "editor", "neovim", "vim", "buffer", "window", "tab",
        "编辑器", "缓冲区", "窗口", "标签页",

        -- GitHub 相关
        "github", "repository", "repo", "git", "pull request", "issue",
        "仓库", "代码库", "拉取请求", "问题",

        -- 文件系统相关
        "filesystem", "file", "directory", "folder", "path",
        "文件系统", "文件", "目录", "文件夹", "路径"
      },
      priority_rules = {
        {
          keywords = {"documentation", "docs", "API", "library", "框架", "文档"},
          tool = "context7",
          priority = 1
        },
        {
          keywords = {"crawl", "scrape", "webpage", "website", "爬取", "网页"},
          tool = "crawl4ai",
          priority = 1
        },
        {
          keywords = {"editor", "neovim", "vim", "buffer", "编辑器", "缓冲区"},
          tool = "neovim",
          priority = 1
        },
        {
          keywords = {"github", "repository", "repo", "git", "仓库", "代码库"},
          tool = "github",
          priority = 1
        },
        {
          keywords = {"filesystem", "file", "directory", "文件系统", "文件", "目录"},
          tool = "filesystem",
          priority = 1
        }
      }
    },
  },

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
}

-- ==================== MCP 特有默认工具 ====================
-- 只添加 MCP 特有的默认工具
M.default_tools = {
  "mcp_servers", -- MCP 服务器工具组（智能自动选择）
}

-- ==================== 精简系统提示配置 ====================
-- 只包含 MCP 特有的提示信息
M.system_prompt = [[## MCP 工具
通过 @{mcp_servers} 可以访问：
- @{context7}: 文档查询
- @{crawl4ai}: 网页爬取
- @{neovim}: 编辑器操作
- @{github}: GitHub 管理
- @{filesystem}: 文件系统操作

## MCP 使用指南
1. 对于 MCP 相关任务，使用 @{mcp_servers} 自动选择最合适的工具
2. 需要确认的操作会询问许可
3. 执行结果会自动反馈]]

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