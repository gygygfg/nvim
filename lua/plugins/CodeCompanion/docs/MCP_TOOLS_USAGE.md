# MCP 工具配置和使用说明

基于 CodeCompanion 扩展系统，已将 MCP 服务器配置为自定义工具调用。

## 配置概述

已成功配置以下组件：

1. **自定义 MCP 工具扩展** (`custom_mcp_tools.lua`)
   - 将 MCP 服务器封装为 CodeCompanion 工具
   - 提供工具组和单个工具调用
   - 支持自动触发和手动调用

2. **主配置集成** (`main.lua`)
   - 集成 MCP Hub 扩展
   - 集成自定义 MCP 工具扩展
   - 配置扩展选项

3. **交互配置更新** (`interactions.lua`)
   - 更新系统提示，包含 MCP 工具信息
   - 更新自主决策指南，指导 AI 使用 MCP 工具

## 可用 MCP 工具

### 服务器工具
- `@{context7}` - Context7 文档查询工具
- `@{crawl4ai}` - Crawl4AI 网页爬取工具  
- `@{neovim}` - Neovim 编辑器操作工具
- `@{github}` - GitHub 仓库管理工具
- `@{filesystem}` - 文件系统操作工具

### 特定功能工具
- `@{context7_search}` - Context7 文档搜索工具
- `@{crawl4ai_crawl}` - Crawl4AI 网页爬取工具

### 工具组
- `@{mcp_servers}` - 所有 MCP 服务器工具组
- `@{web_tools}` - 网页相关工具组（爬取 + 搜索）

## 使用方式

### 1. 直接调用
在 CodeCompanion 聊天中直接使用工具语法：
```
@{context7} 查询 React 文档
@{crawl4ai} 获取 https://example.com 的内容
```

### 2. 工具组调用
使用工具组一次性获得多个相关工具：
```
@{mcp_servers} 使用 MCP 服务器处理任务
@{web_tools} 处理网页相关任务
```

### 3. AI 自动调用
AI 助手会根据系统提示自动识别何时使用 MCP 工具：
- 当用户询问文档时，自动使用 `@{context7}`
- 当用户需要网页内容时，自动使用 `@{crawl4ai}`
- 当用户需要编辑器操作时，自动使用 `@{neovim}`

## 配置详情

### 自定义 MCP 工具扩展
- **位置**: `plugins.CodeCompanion_mcp.custom_mcp_tools.lua`
- **功能**: 
  - 将 MCP 服务器映射为 CodeCompanion 工具
  - 提供工具执行函数
  - 支持参数传递
  - 返回结构化结果

### 扩展选项
```lua
opts = {
  -- 工具组配置
  groups = {
    mcp_servers = { tools = {"context7", "crawl4ai", "neovim", "github", "filesystem"} },
    web_tools = { tools = {"crawl4ai_crawl", "context7_search"} }
  },
  
  -- 自动触发配置
  auto_detect_mcp_usage = true,
  auto_suggest_mcp_tools = true,
  
  -- 结果显示配置
  show_result_in_chat = true,
  format_mcp_results = true,
}
```

## 测试验证

已通过测试验证以下功能：
- ✅ 自定义 MCP 工具扩展加载成功
- ✅ 工具配置正确（7个可用工具）
- ✅ 工具执行函数正常工作
- ✅ MCP 服务器配置正确（5个启用服务器）
- ✅ 参数传递和结果返回正常

## 下一步

1. **实际集成测试**: 在 Neovim 中启动 CodeCompanion，测试 MCP 工具调用
2. **功能扩展**: 根据实际需求添加更多 MCP 工具
3. **错误处理**: 增强工具调用的错误处理和回退机制
4. **性能优化**: 优化工具调用性能和响应时间

## 故障排除

### 工具无法调用
1. 检查 MCP 服务器是否已正确安装和配置
2. 检查 CodeCompanion 扩展配置是否正确加载
3. 查看日志确认工具注册状态

### 结果不显示
1. 检查 `show_result_in_chat` 选项是否启用
2. 确认工具执行函数返回正确格式的结果
3. 检查聊天缓冲区权限设置

### 自动触发不工作
1. 确认 `auto_detect_mcp_usage` 和 `auto_suggest_mcp_tools` 已启用
2. 检查系统提示是否包含 MCP 工具信息
3. 验证关键词匹配逻辑
