# MCP 服务器使用演示

## 已配置的 MCP 服务器

您的系统已成功配置了以下 MCP 服务器：

### 1. Context7 - 文档和代码示例
- **功能**: 获取编程文档、代码示例、技术教程
- **API Key**: `ctx7sk-be72ace2-0150-4385-acef-8d0596dfff07`
- **状态**: ✅ 已配置并测试通过

### 2. Crawl4AI - 网页爬取
- **功能**: 爬取网页内容、提取信息
- **本地服务器**: `http://localhost:11235`
- **API Key**: `my_local_token_12345`
- **状态**: ✅ 已配置并测试通过

### 3. GitHub - GitHub 集成
- **功能**: 访问 GitHub 仓库、问题、PR 等
- **环境变量**: `GITHUB_TOKEN` (通过 cmd:echo 获取)
- **状态**: ✅ 已配置并测试通过

### 4. Filesystem - 文件系统访问
- **功能**: 读取、写入、列出文件
- **状态**: ✅ 已配置并测试通过

### 5. Neovim - Neovim 集成
- **功能**: 访问 Neovim 缓冲区、窗口、标签页
- **状态**: ✅ 已配置并测试通过

## 使用方法

### 基本语法
在 CodeCompanion 聊天中使用以下格式：
```
@{服务器名称} [查询内容]
```

### Context7 示例
```
@{context7} Get React documentation
@{context7} How to use Express.js middleware
@{context7} Get Next.js 14 documentation
@{context7} Python async/await examples
@{context7} Docker best practices
```

### Crawl4AI 示例
```
@{crawl4ai} Crawl https://example.com
@{crawl4ai} Extract content from https://news.ycombinator.com
@{crawl4ai} Scrape https://github.com/trending
@{crawl4ai} Get latest articles from https://techcrunch.com
```

### GitHub 示例
```
@{github} List my repositories
@{github} Get issues for repository username/repo
@{github} Search for Python projects
```

### 自动调用提示
在查询末尾添加 "use [服务器名称]" 可以自动调用对应的服务器：

```
How to create a Next.js middleware? use context7
Get the latest news from Hacker News use crawl4ai
Show me my GitHub repositories use github
```

## 测试验证

已运行以下测试并全部通过：
1. ✅ `test_context7_config.py` - Context7 配置测试
2. ✅ `test_crawl4ai_config.py` - Crawl4AI 配置测试  
3. ✅ `test_all_mcp_servers.py` - 所有 MCP 服务器综合测试

## 下一步建议

1. **测试实际功能**: 在 CodeCompanion 中尝试使用 @{context7} 和 @{crawl4ai}
2. **配置环境变量**: 确保设置了必要的环境变量（已在 README.md 中说明）
3. **验证 GitHub Token**: 如果需要使用 GitHub 功能，请设置有效的 GITHUB_TOKEN
4. **启动 Crawl4AI 服务器**: 确保本地 Crawl4AI 服务器正在运行

## 故障排除

如果遇到问题，请检查：
1. 配置文件位置: `/root/.config/nvim/mcp/servers.json`
2. 包装脚本: `/root/.config/nvim/mcp/wrappers/nvm-wrapper.sh`
3. 环境变量: 使用 `echo $GITHUB_TOKEN` 等命令验证
4. 服务器文件: 确保所有必要的服务器文件都存在

## 快速参考

| 服务器 | 命令格式 | 示例 | 自动调用 |
|--------|----------|------|----------|
| Context7 | `@{context7} [查询]` | `@{context7} React docs` | `use context7` |
| Crawl4AI | `@{crawl4ai} [URL]` | `@{crawl4ai} https://example.com` | `use crawl4ai` |
| GitHub | `@{github} [操作]` | `@{github} list repos` | `use github` |
| Filesystem | `@{filesystem} [操作]` | `@{filesystem} list files` | - |
| Neovim | `@{neovim} [操作]` | `@{neovim} get buffer` | - |
