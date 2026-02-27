# CodeCompanion MCP 集成文档

## 概述

本目录包含 CodeCompanion.nvim 插件的 MCP（Model Context Protocol）集成配置。通过 MCP Hub 插件，CodeCompanion 能够访问各种外部工具和服务，大大扩展了其功能范围。

## 目录结构

```
mcp/
├── README.md                    # 本文档
├── mcp.lua                      # MCP 服务器核心配置
├── mcp_integration.lua          # MCP 集成模块
├── interactions_with_mcp.lua    # MCP 交互策略
└── crawl4ai/                    # Crawl4AI 相关文件
    └── mcp_server_with_api.py   # Crawl4AI MCP 服务器
```

## 集成的 MCP 服务器

### 1. **context7** - 代码库文档服务
- **功能**: 查询编程库和框架的最新文档
- **API 密钥**: `ctx7sk-be72ace2-0150-4385-acef-8d0596dfff07`
- **自动触发关键词**: 
  - documentation, docs, API, library, framework, package
  - npm, pip, install, tutorial, guide, example
  - sample, code snippet, how to use, how to implement
  - best practices, getting started, introduction

### 2. **crawl4ai** - 网页爬取服务
- **功能**: 获取和分析网页内容
- **运行方式**: Python 脚本或 Docker 容器
- **配置**:
  - 基础 URL: `http://localhost:11235`
  - API 密钥: `my_local_token_12345`
- **自动触发关键词**:
  - crawl, scrape, extract, webpage, website, article
  - blog, news, content, latest, recent, update
  - get content from, fetch from, read from, check website
  - visit page, http://, https://, www., .com, .org

### 3. **neovim** - Neovim 编辑器操作服务
- **功能**: 提供编辑器操作功能
- **包含工具**: 文件操作、终端、LSP 功能、缓冲区管理
- **优先级**: 3

### 4. **github** - GitHub 仓库管理服务
- **功能**: GitHub API 集成
- **包含操作**: 仓库管理、issue、PR、代码搜索等
- **环境变量**: `GITHUB_TOKEN` (通过 `cmd:echo $GITHUB_TOKEN` 获取)
- **优先级**: 4

### 5. **web-scout** - 网页搜索服务
- **功能**: DuckDuckGo 网页搜索
- **包含工具**: 
  - `DuckDuckGoWebSearch`: 执行网页搜索
  - `UrlContentExtractor`: 提取网页内容

### 6. **mcphub** - MCP Hub 管理服务
- **功能**: MCP 服务器管理
- **包含工具**:
  - `get_current_servers`: 获取当前服务器状态
  - `toggle_mcp_server`: 启动/停止 MCP 服务器

## 工具访问模式

### 1. 通用 MCP 访问 (`@{mcp}`)
访问所有可用的 MCP 服务器工具。

**示例**:
```
@{mcp} 当前目录下有哪些文件？
```

### 2. 服务器组访问
访问特定服务器的所有工具。

**示例**:
```
neovim工具 读取 main.lua 文件
github工具 创建一个 issue
@{fetch} 获取这个网页
```

### 3. 独立工具访问
精细控制单个工具，格式为 `servername__toolname`。

**示例**:
```
@{neovim__read_file} 显示配置文件
@{github__create_issue} 提交 bug 报告
@{context7__query} 查询 React 文档
```

### 4. 自定义工具组
预定义的工作流工具组，提高效率。

**可用工具组**:
- `@{github_pr_workflow}`: 从 issue 到 PR 的 GitHub 操作流程
- `@{web_research}`: 网页研究和内容提取工作流
- `@{code_analysis}`: 代码分析和文档查询工作流
- `@{mcp_suite}`: 所有 MCP 服务器的完整套件
- `@{development}`: 开发工作流（文档、GitHub、编辑器）

## 资源变量

当 `make_vars = true` 时，MCP 资源可作为变量使用：

**示例**:
```
修复文件中的诊断问题 #{mcp:neovim://diagnostics/buffer}
分析当前缓冲区 #{mcp:neovim:buffer}
获取工作区信息 #{mcp:neovim://workspace}
```

## 斜杠命令

当 `make_slash_commands = true` 时，MCP 提示词可作为斜杠命令使用：

**示例**:
```
/mcp:code_review
/mcp:explain_function
/mcp:generate_tests
```

## 配置详解

### 核心配置文件 (`mcp.lua`)

```lua
-- MCP 服务器配置
M.servers = {
  context7 = {
    enabled = true,
    command = "$HOME/.config/nvim/mcp/wrappers/nvm-wrapper.sh",
    args = {"npx", "-y", "@upstash/context7-mcp", "--api-key", "ctx7sk-be72ace2-0150-4385-acef-8d0596dfff07"},
    autoApprove = true,
    priority = 1,
    description = "Context7 代码库文档服务",
  },
  -- ... 其他服务器配置
}
```

### 集成模块 (`mcp_integration.lua`)

提供 MCP 状态检查和测试功能：

```lua
-- 检查 MCP 服务器状态
M.check_mcp_status(silent)

-- 测试特定 MCP 服务器
M.test_mcp_server(server_name)
```

### 交互策略 (`interactions_with_mcp.lua`)

定义 MCP 工具的交互策略和自动批准规则。

## 使用示例

### 示例 1: 查询文档
```
@{context7__query} 如何用 React 创建一个计数器组件？
```

### 示例 2: 网页研究
```
@{crawl4ai__crawl} https://example.com/article
```

### 示例 3: GitHub 操作
```
@{github__create_issue} 标题："修复登录问题" 内容："用户无法登录系统"
```

### 示例 4: 编辑器操作
```
@{neovim__read_file} 读取当前文件内容
@{neovim__write_file} 写入新内容到文件
```

### 示例 5: 完整工作流
```
@{github_pr_workflow} 
1. 查看 open 状态的 issue
2. 选择一个 issue 进行修复
3. 创建分支并修改代码
4. 提交 PR
```

## 故障排除

### 常见问题

1. **MCP 服务器未启动**
   ```
   :MCPHub status
   :MCPHub start server_name
   ```

2. **工具不可用**
   - 检查服务器是否在 `mcphub__get_current_servers` 的输出中
   - 确认服务器配置中的 `enabled = true`

3. **权限问题**
   - 检查自动批准配置 (`config/mcphub_auto_approve.lua`)
   - 确认敏感操作是否需要手动批准

4. **连接问题**
   - 检查网络连接
   - 验证 API 密钥和配置

### 日志查看
```lua
-- 设置日志级别
log_level = "DEBUG"  -- TRACE > DEBUG > INFO > ERROR

-- 查看日志
:messages
```

## 扩展开发

### 添加新的 MCP 服务器

1. 在 `mcp.lua` 中添加服务器配置：
```lua
new_server = {
  enabled = true,
  command = "command_to_run",
  args = {"arg1", "arg2"},
  autoApprove = true,
  priority = 5,
  description = "服务器描述",
}
```

2. 在 `config/mcphub_integration.lua` 中更新工具组（如果需要）

3. 重启 Neovim 或重新加载配置

### 创建自定义工具组

在 `config/mcphub_integration.lua` 的 `get_custom_tool_groups()` 函数中添加：

```lua
["my_workflow"] = {
  description = "我的自定义工作流",
  tools = {
    "server1__tool1", "server2__tool2", "server3__tool3"
  },
},
```

## 最佳实践

1. **逐步启用功能**
   - 先启用 `make_tools = true`
   - 熟悉后再添加 `make_vars` 和 `make_slash_commands`

2. **安全配置**
   - 对敏感操作使用函数式自动批准
   - 避免全局自动批准

3. **工具发现**
   - 使用 MCP Hub UI 或 CodeCompanion 的工具补全
   - 查看 `mcphub__get_current_servers` 的输出

4. **服务器管理**
   - 通过 MCP Hub UI 管理服务器连接和配置
   - 定期更新服务器版本

5. **性能优化**
   - 根据使用频率设置服务器优先级
   - 禁用不常用的服务器以减少资源占用

## 相关文件

- `config/mcphub_integration.lua` - MCP Hub 完整集成配置
- `config/mcp_tools_config.lua` - MCP 工具配置
- `config/mcphub_auto_approve.lua` - 自动批准配置
- `extensions/mcphub.lua` - MCP Hub 扩展模块
- `init.lua` - 主插件配置

## 更新与维护

### 更新命令
```vim
:Lazy update  " 更新所有插件
:MCPHub update  " 更新 MCP Hub
```

### 检查状态
```vim
:MCPHub status  " 查看服务器状态
:checkhealth mcphub  " 健康检查
```

### 日志位置
- Neovim 消息: `:messages`
- MCP Hub 日志: `~/.local/state/nvim/mcphub.log`
- CodeCompanion 日志: 根据配置的日志级别输出

---

**最后更新**: 2026-02-27  
**版本**: 1.0.0  
**维护者**: CodeCompanion MCP 集成团队