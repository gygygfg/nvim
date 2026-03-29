-- CodeCompanion MCP 动态配置
-- 服务器配置保留，但工具定义通过 MCP Hub 动态发现

local M = {}

-- MCP 服务器基础配置
-- 这些配置用于服务器启动，但工具定义由 MCP Hub 动态管理
M.servers = {
  context7 = {
    enabled = true,
    command = "$HOME/.config/nvim/mcp/wrappers/nvm-wrapper.sh",
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
    command = "docker",
    args = {"exec", "-i", "crawl4ai-mcp", "python", "mcp_server_with_api.py"},
    autoApprove = true,
    priority = 2,
    description = "Crawl4AI 网页爬取服务（Docker 版本）",
    auto_trigger_keywords = {
      "crawl", "scrape", "extract", "webpage", "website", "article",
      "blog", "news", "content", "latest", "recent", "update",
      "get content from", "fetch from", "read from", "check website",
      "visit page", "http://", "https://", "www.", ".com", ".org"
    },
  },

  neovim = {
    enabled = true,
    command = "$HOME/.config/nvim/mcp/wrappers/nvm-wrapper.sh",
    args = {"npx", "mcp-neovim-server"},
    autoApprove = true,
    priority = 3,
    description = "Neovim 编辑器操作服务",
  },

  github = {
    enabled = true,
    command = "$HOME/.config/nvim/mcp/wrappers/nvm-wrapper.sh",
    args = {"npx", "@modelcontextprotocol/server-github"},
    env = { GITHUB_TOKEN = "cmd:echo $GITHUB_TOKEN" },
    autoApprove = true,
    priority = 4,
    description = "GitHub 仓库管理服务",
  },
}

-- 获取启用的服务器
function M.get_enabled_servers()
  local enabled_servers = {}
  for name, config in pairs(M.servers) do
    if config.enabled then
      enabled_servers[name] = config
    end
  end
  return enabled_servers
end

-- 获取服务器配置
function M.get_server_config(server_name)
  return M.servers[server_name]
end

-- 设置函数
function M.setup()
  local config_dir = "~/.config/nvim/mcp"
  -- 如果有 vim 环境，使用 vim.fn.expand
  if vim and vim.fn then
    config_dir = vim.fn.expand(config_dir)
  end

  return {
    mcphub = {
      enabled = true,
      servers = M.servers,
      opts = {
        auto_approve = true,
        config_dir = config_dir,
        
        -- 动态工具配置
        dynamic_tools = {
          enabled = true,
          auto_discover = true,
          refresh_interval = 300,
          cache_tools = true,
        }
      },
    }
  }
end

-- 动态工具发现函数
function M.discover_tools()
  -- 这个函数会从 MCP Hub 发现可用的工具
  -- 在实际实现中，这里会调用 MCP Hub API
  
  local discovered_tools = {}
  
  -- 返回空表，表示工具由 MCP Hub 自动管理
  return discovered_tools
end

-- 获取动态工具信息
function M.get_dynamic_tool_info()
  return {
    discovery_method = "MCP Hub 动态发现",
    auto_refresh = true,
    tool_count = "动态变化",
    last_update = os.time(),
    next_update = os.time() + 300
  }
end

-- MCP 扩展配置
M.extensions = {
  dynamic_discovery = {
    enabled = true,
    description = "MCP 工具动态发现扩展",
    priority = 1
  }
}

return M
