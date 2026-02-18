# MCP 工具使用示例

## 快速开始

### 1. 使用最终配置
```lua
-- 在你的 Neovim 配置中
require("codecompanion").setup({
  interactions = require("plugins.CodeCompanion_mcp.interactions_final").config
})
```

### 2. 在聊天中使用 MCP 工具

#### 基本使用
```markdown
# 查询文档
@{context7} Get React hooks documentation

# 爬取网页
@{crawl4ai} Crawl https://example.com and extract main content

# 操作文件系统
@{filesystem} List files in current directory

# 使用 GitHub
@{github} Search for Python projects
```

#### 使用工具组
```markdown
# 智能选择（推荐）
@{mcp_servers} Find latest web development tutorials

# 网页研究
@{web_tools} Research about machine learning frameworks

# 编程任务
@{coding_suite} Refactor this code and add tests

# 文件操作
@{file_operations} Organize project structure
```

#### 调试和诊断
```markdown
@{debugging_tools} Find why this function is not working
```

## 智能自动选择示例

### 示例 1: 文档查询
```
用户: 我需要查看 Python Flask 的文档和示例
AI: 检测到"文档"关键词，自动使用 @{mcp_servers}
     推荐: context7 (文档查询工具)
     执行: @{context7} Get Python Flask documentation and examples
```

### 示例 2: 网页研究
```
用户: 爬取最新的 AI 新闻文章
AI: 检测到"爬取"关键词，自动使用 @{mcp_servers}
     推荐: crawl4ai (网页爬取工具)
     执行: @{crawl4ai} Crawl latest AI news articles
```

### 示例 3: 代码开发
```
用户: 创建一个新的 React 组件并查看相关文档
AI: 检测到"创建"和"文档"关键词，自动使用组合工具
     推荐: @{coding_suite} + @{mcp_servers}
     执行: 
     1. @{coding_suite} Create React component
     2. @{context7} Get React component best practices
```

## 关键词触发参考

### 自动触发 MCP 工具的关键词

| 关键词类型 | 示例关键词 | 触发工具 |
|-----------|-----------|----------|
| 文档相关 | documentation, docs, API, library, 文档, 说明书 | context7 |
| 网页相关 | crawl, scrape, webpage, website, 爬取, 网页 | crawl4ai |
| 编辑器相关 | editor, neovim, vim, buffer, 编辑器, 缓冲区 | neovim |
| GitHub 相关 | github, repository, repo, git, 仓库, 代码库 | github |
| 文件系统 | filesystem, file, directory, 文件系统, 文件, 目录 | filesystem |
| 通用 MCP | mcp, server, external, service, 服务器, 外部 | mcp_servers |

### 工具组触发关键词

| 工具组 | 触发关键词 | 使用场景 |
|--------|-----------|----------|
| mcp_servers | mcp, server, external, 外部, 服务 | 智能自动选择 |
| web_tools | web, research, 网页, 研究 | 网页内容研究 |
| coding_suite | code, develop, program, 代码, 开发 | 编程任务 |
| file_operations | file, organize, manage, 文件, 管理 | 文件管理 |
| debugging_tools | debug, fix, problem, 调试, 问题 | 问题诊断 |

## 实际工作流示例

### 工作流 1: 学习新技术
```markdown
1. 获取文档: @{context7} Get Vue.js 3 documentation
2. 查看示例: @{context7} Show Vue.js 3 composition API examples
3. 查找教程: @{crawl4ai} Search for Vue.js 3 tutorials
4. 实践代码: @{coding_suite} Create a Vue.js 3 demo project
```

### 工作流 2: 项目重构
```markdown
1. 分析代码: @{grep_search} Find all deprecated functions
2. 查看用法: @{list_code_usages} Show usage of old API
3. 查找替代: @{context7} Find modern alternatives
4. 实施更改: @{insert_edit_into_file} Refactor code
5. 运行测试: @{cmd_runner} Run test suite
```

### 工作流 3: 内容研究
```markdown
1. 收集信息: @{crawl4ai} Crawl latest tech news
2. 整理文档: @{context7} Get relevant documentation
3. 分析内容: 使用 AI 分析收集的信息
4. 生成报告: @{create_file} Create research report
```

## 高级用法

### 组合多个工具
```markdown
# 组合文档查询和网页爬取
1. @{context7} Get official React documentation
2. @{crawl4ai} Search for React community tutorials
3. 对比分析结果
```

### 条件执行
```markdown
# 根据结果决定下一步
1. @{context7} Search for Python async/await patterns
2. 如果找到足够文档，继续 @{coding_suite} 实现
3. 如果文档不足，使用 @{crawl4ai} 查找更多资源
```

### 批量处理
```markdown
# 批量处理多个查询
@{mcp_servers} 
- Get Python FastAPI documentation
- Find Django REST framework examples
- Search for Flask best practices
```

## 故障排除

### 工具未响应
1. 检查 MCP 服务器是否运行: `:MCPStatus`
2. 测试特定工具: `:TestMCPContext7`
3. 查看日志: 检查 Neovim 日志输出

### 配置问题
1. 验证配置: 运行测试脚本
2. 检查路径: 确保所有文件路径正确
3. 重新加载: 重启 Neovim 或重新加载配置

### 性能优化
1. 调整优先级: 修改工具优先级配置
2. 精简关键词: 减少不必要的关键词触发
3. 缓存结果: 对于重复查询使用缓存

## 最佳实践

### 1. 使用工具组
- 优先使用 `@{mcp_servers}` 进行智能选择
- 特定场景使用专用工具组
- 避免手动选择单个工具，除非必要

### 2. 明确指令
- 提供清晰的查询描述
- 指定期望的输出格式
- 包含相关上下文信息

### 3. 分步执行
- 复杂任务分解为多个步骤
- 每一步验证结果
- 根据结果调整后续步骤

### 4. 结果验证
- 检查工具输出是否满足需求
- 必要时请求更多信息
- 使用多个工具交叉验证

## 扩展建议

### 添加自定义工具
1. 在 `mcp.lua` 中添加新的 MCP 服务器配置
2. 在 `mcp_tools_config.lua` 中添加工具定义
3. 更新相关工具组配置
4. 测试新工具功能

### 自定义关键词
1. 根据使用习惯调整关键词
2. 添加领域特定词汇
3. 优化触发准确率

### 集成其他服务
1. 添加新的 MCP 服务器
2. 创建自定义工具组
3. 优化工作流集成