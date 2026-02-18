-- MCP 工具自动集成脚本
-- 在 CodeCompanion 初始化时自动加载和集成 MCP 工具

local M = {}

-- 检查 MCP 服务器配置
function M.check_mcp_config()
  local servers_file = vim.fn.expand("~/.config/nvim/mcp/servers.json")
  local f = io.open(servers_file, "r")
  if not f then
    print("❌ MCP 服务器配置文件不存在: " .. servers_file)
    return false
  end
  
  local content = f:read("*a")
  f:close()
  
  local success, config = pcall(vim.json.decode, content)
  if not success then
    print("❌ MCP 服务器配置文件 JSON 解析失败")
    return false
  end
  
  local servers = config.mcpServers or {}
  local server_count = 0
  
  print("📋 检测到的 MCP 服务器:")
  for server_name, _ in pairs(servers) do
    print("  ✅ " .. server_name)
    server_count = server_count + 1
  end
  
  if server_count == 0 then
    print("⚠️  未找到任何 MCP 服务器配置")
    return false
  end
  
  print("✅ 共检测到 " .. server_count .. " 个 MCP 服务器")
  return true
end

-- 动态加载 MCP 工具到 CodeCompanion
function M.load_mcp_tools()
  -- 导入工具收集模块
  local collect_mcp_tools = require("mcp.tools.collect_mcp_tools")
  
  if not collect_mcp_tools then
    print("❌ 无法加载 MCP 工具收集模块")
    return false
  end
  
  -- 生成工具集
  local toolset = collect_mcp_tools.generate_toolset()
  
  -- 获取 CodeCompanion 实例
  local codecompanion = require("codecompanion")
  if not codecompanion then
    print("❌ CodeCompanion 模块未加载")
    return false
  end
  
  -- 获取当前配置
  local config = codecompanion.config or {}
  local chat_config = config.interactions and config.interactions.chat or {}
  local tools_config = chat_config.tools or {}
  
  -- 添加 MCP 工具到配置
  for _, tool in ipairs(toolset) do
    tools_config[tool.name] = {
      enabled = tool.enabled,
      opts = tool.opts,
      desc = tool.description,
    }
  end
  
  -- 添加 MCP 工具组
  if not tools_config.groups then
    tools_config.groups = {}
  end
  
  tools_config.groups.mcp_suite = {
    description = "MCP 工具套件",
    system_prompt = "我可以使用 MCP 工具来获取外部信息和执行系统操作",
    tools = {
      "context7",
      "crawl4ai",
      "github",
      "filesystem",
      "neovim",
    },
    opts = {
      collapse_tools = true,
      require_approval_for_group = false,
    },
  }
  
  -- 更新配置
  config.interactions = config.interactions or {}
  config.interactions.chat = config.interactions.chat or {}
  config.interactions.chat.tools = tools_config
  
  print("✅ MCP 工具已动态加载到 CodeCompanion")
  return true
end

-- 创建 MCP 工具使用帮助命令
function M.create_help_command()
  vim.api.nvim_create_user_command("MCPHelp", function()
    local help_text = [[
# MCP 工具使用帮助

## 已集成的 MCP 服务器

### 1. Context7 (@{context7})
- **功能**: 获取最新的代码库文档和示例
- **使用方式**: `@{context7} [查询内容]`
- **示例**: 
  - `@{context7} Get React hooks documentation`
  - `@{context7} How to use Express.js middleware`
  - `@{context7__get_library_docs} {library_id: 'react', version: 'latest'}`

### 2. Crawl4AI (@{crawl4ai})
- **功能**: 网页爬取和内容提取
- **使用方式**: `@{crawl4ai} [URL或查询内容]`
- **示例**:
  - `@{crawl4ai} Crawl https://news.ycombinator.com`
  - `@{crawl4ai__crawl_webpage} {url: 'https://example.com', mode: 'markdown'}`
  - `@{crawl4ai} Extract content from https://github.com/trending`

### 3. GitHub (@{github})
- **功能**: GitHub 仓库和项目管理
- **使用方式**: `@{github} [操作]`
- **示例**:
  - `@{github} List my repositories`
  - `@{github__create_issue} {owner: 'username', repo: 'repo', title: 'Bug fix'}`
  - `@{github} Search for Python projects`

### 4. Filesystem (@{filesystem})
- **功能**: 文件系统操作
- **使用方式**: `@{filesystem} [操作]`
- **示例**:
  - `@{filesystem} List files in current directory`
  - `@{filesystem__read_file} {path: '/path/to/file'}`
  - `@{filesystem} Search for files containing 'config'`

### 5. Neovim (@{neovim})
- **功能**: Neovim 编辑器和缓冲区操作
- **使用方式**: `@{neovim} [操作]`
- **示例**:
  - `@{neovim} Get current buffer content`
  - `@{neovim__execute_command} {command: 'echo "Hello"'}`
  - `@{neovim} List all buffers`

## 通用 MCP 工具 (@{mcp})
- **功能**: 访问所有可用的 MCP 服务器
- **使用方式**: `@{mcp} [查询内容]`
- **示例**: `@{mcp} What MCP tools are available?`

## 工具组 (@{mcp_suite})
- **功能**: MCP 工具套件，包含所有 MCP 服务器
- **使用方式**: `@{mcp_suite} [查询内容]`

## 自动调用
在查询中添加以下关键词自动调用相应服务：
- `use context7` - 强制使用 Context7
- `use crawl4ai` - 强制使用 Crawl4AI
- `use mcp` - 使用所有 MCP 服务

## 测试命令
- `:TestMCP` - 测试 MCP 服务是否正常工作
- `:MCPStatus` - 查看 MCP 服务状态

## 更多信息
查看完整文档: `:e ~/.config/nvim/mcp/tools/documentation.md`
    ]]
    
    -- 创建临时缓冲区显示帮助
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "MCP_Help")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(help_text, "\n"))
    
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = 80,
      height = 40,
      col = math.floor((vim.o.columns - 80) / 2),
      row = math.floor((vim.o.lines - 40) / 2),
      style = "minimal",
      border = "rounded",
      title = "MCP 工具使用帮助",
      title_pos = "center",
    })
    
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "readonly", true)
    
    -- 设置按键映射
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>q<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>q<CR>", { noremap = true, silent = true })
  end, {
    desc = "显示 MCP 工具使用帮助"
  })
end

-- 创建 MCP 状态检查命令
function M.create_status_command()
  vim.api.nvim_create_user_command("MCPStatus", function()
    print("🔍 检查 MCP 服务状态...")
    
    -- 检查配置文件
    local servers_file = vim.fn.expand("~/.config/nvim/mcp/servers.json")
    if vim.fn.filereadable(servers_file) == 1 then
      print("✅ MCP 配置文件: " .. servers_file)
    else
      print("❌ MCP 配置文件不存在: " .. servers_file)
    end
    
    -- 检查工具集文件
    local toolset_file = vim.fn.expand("~/.config/nvim/mcp/tools/toolset.lua")
    if vim.fn.filereadable(toolset_file) == 1 then
      print("✅ MCP 工具集文件: " .. toolset_file)
    else
      print("⚠️  MCP 工具集文件不存在: " .. toolset_file)
    end
    
    -- 检查文档文件
    local docs_file = vim.fn.expand("~/.config/nvim/mcp/tools/documentation.md")
    if vim.fn.filereadable(docs_file) == 1 then
      print("✅ MCP 文档文件: " .. docs_file)
    else
      print("⚠️  MCP 文档文件不存在: " .. docs_file)
    end
    
    -- 检查 CodeCompanion 配置
    local codecompanion_config = vim.fn.expand("~/.config/nvim/lua/plugins/codeCompanion.lua")
    if vim.fn.filereadable(codecompanion_config) == 1 then
      print("✅ CodeCompanion 配置文件: " .. codecompanion_config)
    else
      print("❌ CodeCompanion 配置文件不存在: " .. codecompanion_config)
    end
    
    print("\n🚀 使用建议:")
    print("1. 在聊天中使用 @{context7} 获取文档")
    print("2. 在聊天中使用 @{crawl4ai} 爬取网页")
    print("3. 使用 :MCPHelp 查看详细帮助")
    print("4. 使用 :TestMCP 测试服务")
  end, {
    desc = "检查 MCP 服务状态"
  })
end

-- 初始化函数
function M.setup()
  print("🚀 初始化 MCP 工具自动集成...")
  
  -- 检查 MCP 配置
  local config_ok = M.check_mcp_config()
  if not config_ok then
    print("⚠️  MCP 配置检查失败，跳过工具集成")
    return
  end
  
  -- 创建帮助命令
  M.create_help_command()
  M.create_status_command()
  
  -- 尝试动态加载工具
  local success, err = pcall(M.load_mcp_tools)
  if not success then
    print("⚠️  动态加载 MCP 工具失败: " .. tostring(err))
    print("ℹ️  工具仍然可以通过 @{server} 语法使用")
  else
    print("✅ MCP 工具自动集成完成！")
  end
  
  print("\n📚 可用命令:")
  print("  :MCPHelp    - 显示 MCP 工具使用帮助")
  print("  :MCPStatus  - 检查 MCP 服务状态")
  print("  :TestMCP    - 测试 MCP 服务")
  
  print("\n🎯 使用示例:")
  print("  在聊天中输入: @{context7} Get Python documentation")
  print("  在聊天中输入: @{crawl4ai} Crawl https://example.com")
  print("  在查询中添加: use context7 或 use crawl4ai")
end

return M
