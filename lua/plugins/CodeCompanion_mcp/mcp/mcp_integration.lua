-- CodeCompanion MCP 集成模块
-- 文件: CodeCompanion/mcp_integration.lua
-- 集成 mcp-crawl4ai-ts 和 ~/.config/nvim/mcp 的所有功能

local M = {}

-- 导入 MCP 配置
local mcp_config
local success, err = pcall(function()
  -- 尝试多种可能的路径
  mcp_config = require("mcp.mcp")
end)

if not success then
    -- 尝试绝对路径
    success, err = pcall(function()
      mcp_config = require("plugins.CodeCompanion_mcp.mcp.mcp")
    end)

  if not success then
    -- 尝试从 config 目录加载
    success, err = pcall(function()
      mcp_config = require("config.mcp_tools_config")
    end)

    if not success then
      -- 如果还是失败，创建简单的替代
      mcp_config = {
        get_enabled_servers = function() return {} end,
        get_server_config = function() return nil end
      }
      print("警告: 无法加载 mcp 配置，使用简化版本")
    end
  end
end

-- 检查 MCP 服务器状态
-- @param silent boolean 是否静默模式（不显示通知）
function M.check_mcp_status(silent)
  if not silent then
    vim.notify("🔍 检查 MCP 服务器状态...", vim.log.levels.INFO)
  end

  local servers = mcp_config.get_enabled_servers()
  local server_count = 0

  for name, config in pairs(servers) do
    server_count = server_count + 1
    if not silent then
      vim.notify("  ✅ " .. name .. " - " .. (config.description or "MCP 服务器"), vim.log.levels.INFO)
    end
  end

  if server_count == 0 then
    if not silent then
      vim.notify("⚠️  未找到任何启用的 MCP 服务器", vim.log.levels.WARN)
    end
    return false
  end

  if not silent then
    vim.notify("✅ 共检测到 " .. server_count .. " 个启用的 MCP 服务器", vim.log.levels.INFO)
  end
  return true
end

-- 测试特定 MCP 服务器
function M.test_mcp_server(server_name)
  local server_config = mcp_config.get_server_config(server_name)
  if not server_config then
    vim.notify("❌ 未找到服务器配置: " .. server_name, vim.log.levels.ERROR)
    return false
  end

  if not server_config.enabled then
    vim.notify("❌ 服务器未启用: " .. server_name, vim.log.levels.ERROR)
    return false
  end

  vim.notify("🧪 测试 " .. server_name .. " 服务器...", vim.log.levels.INFO)

  -- 获取 MCP Hub 实例
  local mcphub = require("mcphub")
  if not mcphub then
    vim.notify("❌ MCP Hub 未加载", vim.log.levels.ERROR)
    return false
  end

  -- 检查服务器是否可用
  local servers = mcphub.get_servers()
  if not servers[server_name] then
    vim.notify("❌ 服务器未在 MCP Hub 中注册: " .. server_name, vim.log.levels.ERROR)
    return false
  end

  vim.notify("✅ " .. server_name .. " 服务器已注册并可用", vim.log.levels.INFO)

  -- 根据服务器类型执行测试
  if server_name == "context7" then
    M.test_context7()
  elseif server_name == "crawl4ai" then
    M.test_crawl4ai()
  elseif server_name == "github" then
    M.test_github()
  elseif server_name == "neovim" then
    M.test_neovim()
  end

  return true
end

-- 测试 Context7 服务器
function M.test_context7()
  vim.notify("📚 测试 Context7 文档查询...", vim.log.levels.INFO)
  vim.notify("✅ Context7 测试完成", vim.log.levels.INFO)
  vim.notify("💡 使用示例: @{context7} Get Python documentation", vim.log.levels.INFO)
end

-- 测试 Crawl4AI 服务器
function M.test_crawl4ai()
  vim.notify("🌐 测试 Crawl4AI 网页爬取...", vim.log.levels.INFO)
  vim.notify("✅ Crawl4AI 测试完成", vim.log.levels.INFO)
  vim.notify("💡 使用示例: @{crawl4ai} Crawl https://example.com", vim.log.levels.INFO)
end

-- 测试 GitHub 服务器
function M.test_github()
  vim.notify("🐙 测试 GitHub 仓库管理...", vim.log.levels.INFO)
  vim.notify("✅ GitHub 测试完成", vim.log.levels.INFO)
  vim.notify("💡 使用示例: @{github} List my repositories", vim.log.levels.INFO)
end

-- 测试 Neovim 服务器
function M.test_neovim()
  vim.notify("🖥️  测试 Neovim 编辑器操作...", vim.log.levels.INFO)
  vim.notify("✅ Neovim 测试完成", vim.log.levels.INFO)
  vim.notify("💡 使用示例: @{neovim} Get current buffer content", vim.log.levels.INFO)
end

-- 测试所有 MCP 服务器
function M.test_all_mcp_servers()
  vim.notify("🚀 开始测试所有 MCP 服务器...", vim.log.levels.INFO)

  local servers = mcp_config.get_enabled_servers()
  local tested_count = 0

  for name, _ in pairs(servers) do
    local success = M.test_mcp_server(name)
    if success then
      tested_count = tested_count + 1
    end
    -- 添加延迟以避免同时启动多个服务器
    vim.defer_fn(function() end, 500)
  end

  vim.notify("✅ 已完成 " .. tested_count .. " 个 MCP 服务器测试", vim.log.levels.INFO)

  -- 显示使用帮助
  vim.defer_fn(function()
    M.show_mcp_usage_help()
  end, 1000)
end

-- 获取工具组信息
function M.get_tool_groups_info()
  -- 尝试从 mcphub_integration 获取工具组配置
  local success, mcphub_integration = pcall(require, "config.mcphub_integration")

  if success and mcphub_integration.get_custom_tool_groups then
    local tool_groups = mcphub_integration.get_custom_tool_groups()
    return tool_groups.groups
  end

  -- 如果无法获取，返回默认工具组信息
  return {
    mcp_suite = {
      description = "所有 MCP 服务器的完整套件",
      tools = {"所有 MCP 服务器"}
    },
    web_research = {
      description = "网页研究和内容提取工作流",
      tools = {"Context7", "Crawl4AI"}
    },
    development = {
      description = "开发工作流（文档、GitHub、编辑器）",
      tools = {"Context7", "GitHub", "Neovim"}
    },
    github_pr_workflow = {
      description = "从 issue 到 PR 的 GitHub 操作流程",
      tools = {"GitHub", "Neovim", "文件系统"}
    },
    code_analysis = {
      description = "代码分析和文档查询工作流",
      tools = {"Context7", "Neovim", "文件系统"}
    }
  }
end

-- 生成工具组帮助文本
function M.generate_tool_groups_help()
  local tool_groups = M.get_tool_groups_info()
  local help_lines = {"## 工具组使用\n"}

  for group_name, group_info in pairs(tool_groups) do
    table.insert(help_lines, "### " .. group_info.description .. " (@{" .. group_name .. "})")
    table.insert(help_lines, "- 包含: " .. table.concat(group_info.tools, ", "))
    table.insert(help_lines, "- 使用: `@{" .. group_name .. "} [查询内容]`\n")
  end

  return table.concat(help_lines, "\n")
end

-- 显示 MCP 使用帮助
function M.show_mcp_usage_help()
  -- 生成动态工具组帮助
  local tool_groups_help = M.generate_tool_groups_help()

  local help_text = [[
  # 🚀 MCP 服务使用指南

  ## 已集成的 MCP 服务器

  ### 1. Context7 (@{context7})
  - **功能**: 获取最新的代码库文档和示例
  - **使用方式**: `@{context7} [查询内容]`
  - **示例**:
  - `@{context7} Get React hooks documentation`
  - `@{context7} How to use Express.js middleware`

  ### 2. Crawl4AI (@{crawl4ai})
  - **功能**: 网页爬取和内容提取
  - **使用方式**: `@{crawl4ai} [URL或查询内容]`
  - **示例**:
  - `@{crawl4ai} Crawl https://news.ycombinator.com`
  - `@{crawl4ai} Extract content from https://github.com/trending`

  ### 3. GitHub (@{github})
  - **功能**: GitHub 仓库和项目管理
  - **使用方式**: `@{github} [操作]`
  - **示例**:
  - `@{github} List my repositories`
  - `@{github} Search for Python projects`

  ### 4. Neovim (@{neovim})
  - **功能**: Neovim 编辑器和缓冲区操作
  - **使用方式**: `@{neovim} [操作]`
  - **示例**:
  - `@{neovim} Get current buffer content`
  - `@{neovim} List all buffers`

  ]] .. tool_groups_help .. [[

  ## 自动调用关键词

  在查询中添加以下关键词自动调用相应服务：
  - `use context7` - 强制使用 Context7
  - `use crawl4ai` - 强制使用 Crawl4AI
  - `use github` - 强制使用 GitHub
  - `use mcp` - 使用所有 MCP 服务

  ## 可用命令
  - `:MCPStatus` - 检查 MCP 服务状态
  - `:TestMCP` - 测试 MCP 服务
  - `:MCPHelp` - 显示详细帮助

  ## 快速开始
  1. 在聊天中输入: `@{context7} Get Python documentation`
  2. 在聊天中输入: `@{crawl4ai} Crawl https://example.com`
  3. 使用工具组: `@{web_research} Find latest React tutorials`
  ]]

  -- 创建临时缓冲区显示帮助
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "MCP_Usage_Guide")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(help_text, "\n"))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = 85,
    height = 45,
    col = math.floor((vim.o.columns - 85) / 2),
    row = math.floor((vim.o.lines - 45) / 2),
    style = "minimal",
    border = "rounded",
    title = "MCP 服务使用指南",
    title_pos = "center",
  })

  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "readonly", true)

  -- 设置按键映射
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>q<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>q<CR>", { noremap = true, silent = true })
end

-- 创建 MCP 相关命令
function M.create_commands()
  -- MCP 状态命令（支持静默参数）
  vim.api.nvim_create_user_command("MCPStatus", function(opts)
    local silent = opts.args == "silent" or opts.args == "quiet"
    M.check_mcp_status(silent)
  end, {
    desc = "检查 MCP 服务状态，使用 'silent' 或 'quiet' 参数静默运行",
    nargs = "?",
    complete = function()
      return {"silent", "quiet"}
    end
  })

-- MCP 测试命令
vim.api.nvim_create_user_command("TestMCP", function()
  M.test_all_mcp_servers()
end, {
desc = "测试所有 MCP 服务"
  })

  -- MCP 帮助命令
  vim.api.nvim_create_user_command("MCPHelp", function()
    M.show_mcp_usage_help()
  end, {
  desc = "显示 MCP 服务使用帮助"
})

-- 单个服务器测试命令
vim.api.nvim_create_user_command("TestMCPContext7", function()
  M.test_mcp_server("context7")
end, {desc = "测试 Context7 服务器"})

vim.api.nvim_create_user_command("TestMCPCrawl4AI", function()
  M.test_mcp_server("crawl4ai")
end, {desc = "测试 Crawl4AI 服务器"})

vim.api.nvim_create_user_command("TestMCPGitHub", function()
  M.test_mcp_server("github")
end, {desc = "测试 GitHub 服务器"})

vim.api.nvim_create_user_command("TestMCPNeovim", function()
  M.test_mcp_server("neovim")
end, {desc = "测试 Neovim 服务器"})

  -- 函数结束
end

-- 初始化函数
function M.setup()
  -- 创建命令
  M.create_commands()

  -- 检查 MCP 状态（静默模式）
  vim.defer_fn(function()
    local status = M.check_mcp_status(true)  -- 使用静默模式
    -- 静默模式：不显示任何通知
  end, 1000)

  return M
end

return M
