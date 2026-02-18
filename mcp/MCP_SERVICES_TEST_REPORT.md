# MCP 服务测试报告

## 测试时间
2026-02-16

## 测试环境
- 目录: /root/.config/nvim/mcp
- Node.js 版本: v24.13.0
- NVM 包装脚本: 已配置并可用

## 测试结果

### 1. Context7 MCP 服务 ✅ **通过**
- **配置状态**: 已正确配置
- **API Key**: ctx7sk-be72ace2-0150-4385-acef-8d0596dfff07
- **启动方式**: 使用 nvm-wrapper.sh 包装脚本
- **测试结果**: 服务包可用，命令行参数正确

### 2. Crawl4AI MCP 服务 ✅ **通过**
- **配置状态**: 已正确配置
- **服务器路径**: /root/.config/nvim/lua/plugins/mcp-crawl4ai-ts/dist/index.js
- **环境变量**:
  - CRAWL4AI_BASE_URL: http://localhost:11235
  - CRAWL4AI_API_KEY: my_local_token_12345
  - SERVER_NAME: MyLocalCrawler
  - SERVER_VERSION: 1.0.0
- **测试结果**: 服务器可以正常启动

### 3. NVM 包装脚本 ✅ **通过**
- **脚本位置**: wrappers/nvm-wrapper.sh
- **可执行性**: 可执行
- **功能测试**: 可以正确加载 nvm 环境并执行 Node.js 命令

## 配置文件状态

### servers.json 配置摘要:
```json
{
  "context7": {
    "command": "/root/.config/nvim/mcp/wrappers/nvm-wrapper.sh",
    "args": ["npx", "-y", "@upstash/context7-mcp", "--api-key", "ctx7sk-be72ace2-0150-4385-acef-8d0596dfff07"],
    "autoApprove": true
  },
  "crawl4ai": {
    "command": "node",
    "args": ["/root/.config/nvim/lua/plugins/mcp-crawl4ai-ts/dist/index.js"],
    "env": {
      "CRAWL4AI_BASE_URL": "http://localhost:11235",
      "CRAWL4AI_API_KEY": "my_local_token_12345",
      "SERVER_NAME": "MyLocalCrawler",
      "SERVER_VERSION": "1.0.0"
    },
    "autoApprove": true
  }
}
```

## 使用说明

### 在 CodeCompanion 中使用:

1. **Context7** (文档和代码搜索):
   ```
   @{context7} Get React documentation
   @{context7} How to use Express.js middleware
   @{context7} Get Next.js 14 documentation
   ```

2. **Crawl4AI** (网页爬取):
   ```
   @{crawl4ai} Crawl https://example.com
   @{crawl4ai} Extract content from https://news.ycombinator.com
   ```

### 自动调用提示:
- 在提示中添加 "use context7" 可以自动调用 Context7
- 在提示中添加 "use crawl4ai" 可以自动调用 Crawl4AI

## 注意事项

1. **Context7**:
   - 需要有效的 API Key 才能工作
   - 提供最新的文档和代码示例

2. **Crawl4AI**:
   - 需要本地 Crawl4AI 服务器运行在端口 11235
   - 如果服务器未运行，需要先启动它
   - 支持网页爬取、内容提取、截图等功能

3. **环境要求**:
   - Node.js 18+ (当前: v24.13.0)
   - NVM 环境已正确配置
   - MCP Hub 插件已安装

## 下一步建议

1. **重启 Neovim** 或运行 `:Lazy sync` 使配置生效
2. **测试实际功能**:
   - 在 CodeCompanion 中测试 Context7 文档搜索
   - 启动 Crawl4AI 服务器并测试网页爬取
3. **监控日志**:
   - 查看 MCP 服务器启动日志
   - 检查 API 调用是否成功

## 结论

两个 MCP 服务都已正确配置并可以通过测试。配置完整，环境准备就绪，可以正常使用。

