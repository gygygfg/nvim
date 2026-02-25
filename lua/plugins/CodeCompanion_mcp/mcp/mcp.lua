-- CodeCompanion MCP 配置
-- 文件: CodeCompanion/mcp.lua

local M = {}

-- MCP 服务器配置
M.servers = {
  context7 = {
    enabled = true,
    command = "/root/.config/nvim/mcp/wrappers/nvm-wrapper.sh",
    args = {"npx", "-y", "@upstash/context7-mcp", "--api-key", "ctx7sk-be72ace2-0150-4385-acef-8d0596dfff07"},
    autoApprove = true,
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
    command = "docker",
    args = {"exec", "-i", "crawl4ai-mcp", "python", "mcp_server_with_api.py"},
    autoApprove = true,
    priority = 2, -- 中等优先级，用于网页内容查询
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
      },
    }
  }
end

-- 获取所有启用的服务器
function M.get_enabled_servers()
  local enabled_servers = {}
  for name, config in pairs(M.servers) do
    if config.enabled then
      enabled_servers[name] = config
    end
  end
  return enabled_servers
end

-- 获取特定服务器配置
function M.get_server_config(server_name)
  return M.servers[server_name]
end

-- MCP 扩展配置
-- 暂时禁用 MCP 扩展，避免加载错误
M.extensions = {}

return M
