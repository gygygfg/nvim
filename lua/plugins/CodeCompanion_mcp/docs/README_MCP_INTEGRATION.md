# CodeCompanion MCP 功能集成

## 概述

本目录已成功集成以下 MCP 功能：

1. **mcp-crawl4ai-ts** - 网页爬取和内容提取服务器
2. **~/.config/nvim/mcp** - 所有 MCP 服务器配置和工具

## 集成内容

### 1. 配置文件
- `mcp.lua` - 完整的 MCP 服务器配置，包含所有服务器详细设置
- `mcp_integration.lua` - MCP 集成模块，提供状态检查、测试和帮助功能
- `config.lua` - 更新以支持 MCP 集成

### 2. 集成的 MCP 服务器

| 服务器 | 功能 | 状态 | 优先级 |
|--------|------|------|--------|
| **context7** | 代码库文档查询 | ✅ 已启用 | 1 (最高) |
| **crawl4ai** | 网页爬取和内容提取 | ✅ 已启用 | 2 |
| **neovim** | 编辑器操作 | ✅ 已启用 | 3 |
| **github** | GitHub 仓库管理 | ✅ 已启用 | 4 |
| **filesystem** | 文件系统操作 | ✅ 已启用 | 5 |

### 3. 工具组配置
- **mcp_suite** - 所有 MCP 服务器工具组
- **web_research** - 网页研究工具组 (Context7 + Crawl4AI)
- **development** - 开发工具组 (Context7 + GitHub + Neovim)

## 使用方法

### 1. 基本使用
在 CodeCompanion 聊天中直接使用 `@{服务器名}` 语法：

```text
@{context7} Get React hooks documentation
@{crawl4ai} Crawl https://example.com
@{github} List my repositories
@{filesystem} List files in current directory
@{neovim} Get current buffer content
```

### 2. 工具组使用
```text
@{mcp_suite} Find information about Python web frameworks
@{web_research} Get latest news about AI developments
@{development} Help me with this coding problem
```

### 3. 自动调用
在查询中添加关键词自动调用相应服务：
- `use context7` - 强制使用 Context7
- `use crawl4ai` - 强制使用 Crawl4AI
- `use github` - 强制使用 GitHub
- `use mcp` - 使用所有 MCP 服务

## 可用命令

### 状态检查
```vim
:MCPStatus    " 检查 MCP 服务状态
```

### 测试命令
```vim
:TestMCP              " 测试所有 MCP 服务
:TestMCPContext7      " 测试 Context7 服务器
:TestMCPCrawl4AI      " 测试 Crawl4AI 服务器
:TestMCPGitHub        " 测试 GitHub 服务器
:TestMCPFilesystem    " 测试 Filesystem 服务器
:TestMCPNeovim        " 测试 Neovim 服务器
```

### 帮助命令
```vim
:MCPHelp    " 显示 MCP 服务使用帮助
```

## 配置详情

### Crawl4AI 配置
- **服务器路径**: `/root/.config/nvim/lua/plugins/mcp-crawl4ai-ts/dist/index.js`
- **环境变量**:
  - `CRAWL4AI_BASE_URL`: http://localhost:11235
  - `CRAWL4AI_API_KEY`: my_local_token_12345
  - `SERVER_NAME`: MyLocalCrawler
  - `SERVER_VERSION`: 1.0.0

### Context7 配置
- **API Key**: ctx7sk-be72ace2-0150-4385-acef-8d0596dfff07
- **包装器**: nvm-wrapper.sh

### 其他服务器
所有服务器都使用 `nvm-wrapper.sh` 包装器，确保在正确的 Node.js 环境中运行。

## 文件结构

```
CodeCompanion/
├── init.lua              # 主插件配置
├── config.lua            # 配置函数（已更新）
├── mcp.lua              # MCP 服务器配置（已更新）
├── mcp_integration.lua  # MCP 集成模块（新增）
├── adapters.lua         # 适配器配置
├── interactions.lua     # 交互策略
└── display.lua          # 显示配置
```

## 验证集成

1. 重启 Neovim 或重新加载配置
2. 运行 `:MCPStatus` 检查所有服务器状态
3. 运行 `:TestMCP` 测试所有服务器
4. 在 CodeCompanion 聊天中尝试使用 MCP 服务

## 故障排除

### 1. 服务器未启动
- 检查 `~/.config/nvim/mcp/servers.json` 文件是否存在
- 确保所有服务器命令路径正确
- 检查环境变量设置

### 2. MCP Hub 未加载
- 确保已安装 `mcphub.nvim` 插件
- 运行 `:checkhealth mcphub` 检查状态

### 3. 特定服务器问题
- 查看服务器日志：`~/.local/state/nvim/mcp-hub.log`
- 检查服务器进程是否运行

## 扩展开发

要添加新的 MCP 服务器：

1. 在 `mcp.lua` 的 `M.servers` 表中添加服务器配置
2. 在 `mcp_integration.lua` 中添加相应的测试函数
3. 更新工具组配置（如果需要）
4. 重新加载配置测试

## 性能优化

- 启用延迟加载：服务器在首次使用时才启动
- 启用工具定义缓存：减少重复加载
- 按需启动：根据关键词自动触发相应服务器

## 支持

如有问题，请检查：
1. MCP 配置文件：`~/.config/nvim/mcp/servers.json`
2. MCP Hub 日志：`~/.local/state/nvim/mcp-hub.log`
3. CodeCompanion 日志：`:CodeCompanionLog`
