# MCP 服务器配置说明

## 环境变量设置

要使 MCP 服务器正常工作，需要设置以下环境变量：

### 1. GitHub MCP 服务器
```bash
# 获取 GitHub Personal Access Token
# 访问：https://github.com/settings/tokens
# 创建具有 repo 权限的 token
export GITHUB_TOKEN="your_github_token_here"
```

### 2. Brave Search MCP 服务器
```bash
# 获取 Brave Search API Key
# 访问：https://brave.com/search/api/
export BRAVE_API_KEY="your_brave_api_key_here"
```

### 3. Context7 MCP 服务器
```bash
# Context7 API Key 已配置在 servers.json 中
# 您的 API Key: ctx7sk-be72ace2-0150-4385-acef-8d0596dfff07

# 如果需要设置环境变量（可选）
export CONTEXT7_API_KEY="ctx7sk-be72ace2-0150-4385-acef-8d0596dfff07"
```

### 4. 持久化环境变量

将以下内容添加到 `~/.bashrc` 或 `~/.zshrc` 中：

```bash
# MCP 服务器环境变量
export GITHUB_TOKEN="your_github_token_here"
export BRAVE_API_KEY="your_brave_api_key_here"
export CONTEXT7_API_KEY="your_context7_api_key_here"  # 可选
```

## NVM 配置说明

系统检测到您使用 nvm 管理 Node.js。已自动配置包装脚本确保 MCP 服务器在正确的 Node.js 环境中运行。

### 已配置的包装脚本
- **通用包装脚本**: `/root/.config/nvim/mcp/wrappers/nvm-wrapper.sh`
- **Context7 专用脚本**: `/root/.config/nvim/mcp/wrappers/context7-wrapper.sh`

### 包装脚本功能
1. 自动加载 nvm 环境
2. 确保使用正确的 Node.js 版本 (v24.13.0)
3. 传递所有参数给原始命令

### 当前 Node.js 环境
- **版本**: v24.13.0 (LTS Krypton)
- **路径**: `/root/.nvm/versions/node/v24.13.0/bin/node`
- **npm 版本**: 11.7.0
- **npx 版本**: 11.7.0

## 服务器说明

### 内置服务器
1. **@neovim** - Neovim 集成服务器
   - 无需额外配置
   - 提供文件操作、终端、LSP 功能

2. **@mcphub** - MCP Hub 管理服务器
   - 无需额外配置
   - 提供服务器管理功能

### 外部服务器
1. **@github** - GitHub 集成
   - 需要 GITHUB_TOKEN
   - 功能：创建 issue、管理仓库等

2. **@filesystem** - 文件系统访问
   - 无需额外配置
   - 功能：文件浏览、搜索等

3. **@brave-search** - Brave 搜索
   - 需要 BRAVE_API_KEY
   - 功能：网页搜索

4. **@context7** - Context7 代码文档服务
   - 可选：CONTEXT7_API_KEY（用于更高速率限制和私有仓库）
   - 功能：获取最新的代码库文档和示例
   - 特点：
     - 提供最新的、版本特定的文档
     - 直接从源代码获取代码示例
     - 支持自动调用规则
     - 避免过时的 API 信息和幻觉代码

## 使用方法

在 CodeCompanion 聊天中，可以使用以下方式调用 MCP 工具：

### 通用访问
```
@{mcp} What files are in the current directory?
```

### 服务器组访问
```
@{neovim} Read the main.lua file
@{github} Create an issue
```

### 单个工具访问
```
@{neovim__read_file} Show me the config file
@{github__create_issue} File a bug report
```

### 资源变量
```
Fix diagnostics in the file #{mcp:neovim://diagnostics/buffer}
```

### 斜杠命令
```
/mcp:code_review
/mcp:explain_function
```