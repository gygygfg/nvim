# MCP 服务器安装说明

## 快速安装步骤

1. **重启 Neovim** 或运行以下命令安装插件：
   ```vim
   :Lazy sync
   ```

2. **设置环境变量**（可选但推荐）：
   ```bash
   # 添加到 ~/.bashrc 或 ~/.zshrc
   export GITHUB_TOKEN="your_github_token"
   export BRAVE_API_KEY="your_brave_api_key"
   export CONTEXT7_API_KEY="your_context7_api_key"  # 可选
   ```

3. **测试 MCP 功能**：
   - 打开 CodeCompanion 聊天：`:CodeCompanionChat`
   - 测试命令：
     ```
     @{mcp} What MCP servers are available?
     ```
     ```
     @{neovim} List files in current directory
     ```
     ```
     @{context7} Get documentation for React
     ```

## NVM 集成说明

检测到您使用 nvm 管理 Node.js，已自动配置包装脚本确保 MCP 服务器在正确的 Node.js 环境中运行。

### 包装脚本位置
- `/root/.config/nvim/mcp/wrappers/nvm-wrapper.sh` - 通用包装脚本
- `/root/.config/nvim/mcp/wrappers/context7-wrapper.sh` - Context7 专用脚本

### 当前 Node.js 环境
- **版本**: v24.13.0 (Node.js LTS)
- **管理工具**: nvm 0.40.3
- **已自动集成**: 所有 MCP 服务器配置已更新使用包装脚本

## 已配置的 MCP 服务器

### 1. **@neovim** - Neovim 集成
- **功能**：文件操作、终端、LSP 功能
- **配置**：无需额外配置

### 2. **@github** - GitHub 集成
- **功能**：创建 issue、管理仓库等
- **需要**：`GITHUB_TOKEN` 环境变量

### 3. **@filesystem** - 文件系统访问
- **功能**：文件浏览、搜索等
- **配置**：无需额外配置

### 4. **@brave-search** - Brave 搜索
- **功能**：网页搜索
- **需要**：`BRAVE_API_KEY` 环境变量

### 5. **@context7** - Context7 代码文档
- **功能**：获取最新的代码库文档和示例
- **特点**：
  - 提供最新的、版本特定的文档
  - 直接从源代码获取代码示例
  - 避免过时的 API 信息和幻觉代码
  - 支持自动调用规则
- **需要**：`CONTEXT7_API_KEY`（可选，用于更高速率限制）

## Context7 使用技巧

### 基本使用
```
@{context7} Get React documentation
```

### 特定工具使用
```
@{context7__resolve_library_id} Find information about Next.js
@{context7__get_library_docs} Get docs for Express.js version 4.18.0
```

### 在提示中使用
在 CodeCompanion 聊天中，可以在提示中添加 "use context7"：
```
How to create a Next.js middleware with JWT authentication? use context7
```

### 设置自动调用规则
在 CodeCompanion 系统提示中已经配置了 Context7 的自动使用指南。

## 故障排除

### MCP 服务器未启动
1. 检查插件是否安装：`:Lazy`
2. 检查 MCP Hub 配置：查看 `~/.config/nvim/mcp/servers.json`
3. 重启 Neovim

### 环境变量问题
1. 确认环境变量已设置：`echo $GITHUB_TOKEN`
2. 重新加载 shell 配置：`source ~/.bashrc`
3. 在 Neovim 中重新设置：`:let $GITHUB_TOKEN='your_token'`

### Context7 特定问题
1. 如果没有 API key，Context7 仍可使用基础功能
2. 获取 API key：访问 https://context7.com/dashboard
3. 检查网络连接：Context7 需要访问远程服务

## 高级配置

### 添加更多 MCP 服务器
编辑 `~/.config/nvim/mcp/servers.json` 文件，按照现有格式添加新的服务器配置。

### 修改自动批准设置
编辑 `~/.config/nvim/lua/plugins/codeCompanion.lua`，修改 `auto_approve` 设置。

### 自定义工具权限
在 CodeCompanion 配置中调整各工具的 `require_approval_before` 设置。

## 支持

- MCP Hub 文档：https://github.com/ravitemer/mcphub.nvim
- Context7 文档：https://context7.com/docs
- CodeCompanion 文档：https://github.com/olimorris/codecompanion.nvim