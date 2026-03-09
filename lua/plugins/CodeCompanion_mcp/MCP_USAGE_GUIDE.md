# MCP 工具使用指南（修复版）

## 问题解决

已成功修复 "Server not found" 错误。问题原因是服务器名称不匹配：

### 原问题
- **错误**: `Server not found`，服务器 "mcp" 不存在
- **原因**: MCP Hub 中的服务器名称使用连字符（如 `web-scout`, `chrome-devtools`），但配置中使用了不同的命名

### 解决方案
1. **使用实际服务器名称**：工具调用时使用 MCP Hub 的实际名称（带连字符）
2. **标准化工具组名称**：工具组访问时使用标准化名称（带下划线）
3. **更新系统提示**：提供详细的使用说明

## 当前可用的 MCP 服务器

根据 MCP Hub 状态，当前有 7 个服务器正在运行：
- `context7` - Context7 代码库文档服务
- `web-scout` - 网页搜索和内容提取服务
- `github` - GitHub 仓库管理服务
- `neovim` - Neovim 编辑器操作服务
- `chrome-devtools` - Chrome DevTools 浏览器自动化服务
- `mcphub` - MCP Hub 服务器管理服务

## 三种使用方式

### 1. 通用 MCP 访问（推荐）
使用 `@{use_mcp_tool}` 工具直接调用 MCP 服务器：

```bash
use_mcp_tool context7 query-docs {libraryId: "/python/docs", query: "How to use lists"}
use_mcp_tool github list_issues {owner: "yourname", repo: "yourrepo"}
use_mcp_tool web-scout UrlContentExtractor {url: "https://example.com"}
```

### 2. 服务器组访问
使用工具组访问特定服务器的所有工具：

```bash
@{context7} Search for Python documentation
@{github} List my repositories
@{neovim} Get current buffer content
@{web_scout} Search for latest news
@{chrome_devtools} Take a screenshot of webpage
```

**注意**：工具组名称使用下划线（如 `web_scout`, `chrome_devtools`），但实际服务器名称是连字符。

### 3. 独立工具访问
直接调用特定工具：

```bash
web-scout__UrlContentExtractor {url: "https://example.com"}
github__create_issue {owner: "yourname", repo: "yourrepo", title: "Bug report"}
neovim__read_file {path: "main.lua"}
context7__query-docs {libraryId: "/react/docs", query: "How to use hooks"}
```

**注意**：工具名中的服务器部分使用实际名称（带连字符）。

## 常见工具示例

### Context7 文档查询
```bash
# 搜索 Python 文档
use_mcp_tool context7 query-docs {libraryId: "/python/docs", query: "How to use lists"}

# 搜索 React 文档
context7__query-docs {libraryId: "/react/docs", query: "How to use hooks"}
```

### GitHub 操作
```bash
# 列出仓库
@{github} List my repositories

# 创建 issue
github__create_issue {owner: "yourname", repo: "yourrepo", title: "Bug report", body: "详细描述"}

# 搜索代码
github__search_code {q: "python flask"}
```

### 网页搜索和提取
```bash
# 搜索网页
web-scout__DuckDuckGoWebSearch {query: "latest AI news", maxResults: 5}

# 提取网页内容
web-scout__UrlContentExtractor {url: "https://news.ycombinator.com"}
```

### Neovim 编辑器操作
```bash
# 读取当前文件
@{neovim} Get current buffer content

# 执行命令
neovim__execute_command {command: "ls -la", cwd: "."}

# 读取文件
neovim__read_file {path: "config.lua"}
```

### Chrome DevTools 浏览器自动化
```bash
# 导航到网页
chrome-devtools__navigate_page {url: "https://example.com", type: "url"}

# 截图
chrome-devtools__take_screenshot {filePath: "screenshot.png"}

# 点击元素
chrome-devtools__click {uid: "element_id"}
```

### MCP Hub 管理
```bash
# 查看服务器状态
mcphub__get_current_servers {}

# 切换服务器
mcphub__toggle_mcp_server {server_name: "context7", action: "stop"}
```

## 故障排除

### 1. "Server not found" 错误
**问题**: 服务器名称不正确
**解决**: 使用正确的服务器名称（见上面的列表）

### 2. 工具调用失败
**问题**: 工具名称或参数不正确
**解决**: 
- 检查工具名称是否正确
- 确保参数格式正确（JSON 对象）
- 使用 `@{use_mcp_tool}` 进行调试

### 3. 权限问题
**问题**: 某些工具需要批准
**解决**: 
- 检查自动批准配置
- 手动批准敏感操作

## 最佳实践

1. **先测试简单命令**: 从简单的 `@{github} List my repositories` 开始
2. **使用工具组**: 对于不熟悉的服务器，先使用工具组探索可用工具
3. **查看工具文档**: 使用 `@{use_mcp_tool}` 查看工具的参数格式
4. **逐步复杂化**: 从简单查询开始，逐步添加复杂参数
5. **保存成功示例**: 记录成功的工作流供以后使用

## 验证修复

要验证修复是否成功：

1. **检查服务器状态**:
   ```bash
   mcphub__get_current_servers {}
   ```

2. **测试简单命令**:
   ```bash
   @{github} List my repositories
   ```

3. **测试实际工具**:
   ```bash
   web-scout__DuckDuckGoWebSearch {query: "test", maxResults: 3}
   ```

如果上述命令都能正常工作，说明 MCP 工具配置已成功修复！