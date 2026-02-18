# MCP 工具配置与集成指南

## 概述

本文档提供了将 MCP 工具集成到 CodeCompanion 的完整指南。我们采用了模块化的方法，将基础配置和 MCP 工具配置分离，便于管理和维护。

## 文件结构

```
.
├── interactions_base.lua          # 基础配置（不包含 MCP 工具）
├── mcp_tools_config.lua          # MCP 工具配置定义
├── add_mcp_tools.lua             # MCP 工具添加脚本
├── interactions_final.lua        # 最终配置（基础 + MCP）
└── MCP_TOOLS_SETUP_GUIDE.md      # 本指南
```

## 配置说明

### 1. 基础配置 (`interactions_base.lua`)
- 包含 CodeCompanion 的基本工具配置
- 不包含任何 MCP 相关配置
- 提供了完整的工具系统基础

### 2. MCP 工具配置 (`mcp_tools_config.lua`)
- 定义了所有 MCP 工具的配置
- 基于 `mcp.lua` 中的服务器配置生成
- 包含：
  - MCP 服务器配置（来自 mcp.lua）
  - MCP 工具定义
  - 工具组定义
  - 默认工具配置
  - 完整的系统提示

### 3. MCP 工具添加脚本 (`add_mcp_tools.lua`)
- 提供函数将 MCP 工具添加到基础配置
- 包含验证测试函数
- 模块化设计，便于重用

### 4. 最终配置 (`interactions_final.lua`)
- 组合基础配置和 MCP 工具配置
- 简洁的集成方式
- 易于维护和更新

## MCP 工具列表

### 单个 MCP 工具
1. **context7** - Context7 文档查询工具
2. **crawl4ai** - Crawl4AI 网页爬取工具
3. **neovim** - Neovim 编辑器操作工具
4. **github** - GitHub 仓库管理工具
5. **filesystem** - 文件系统操作工具
6. **context7_search** - Context7 文档搜索工具
7. **crawl4ai_crawl** - Crawl4AI 网页爬取工具
8. **mcp_servers** - MCP 服务器工具组（智能自动选择）

### 工具组
1. **mcp_servers** - MCP 服务器工具组（智能自动选择）
2. **web_tools** - 网页相关工具组
3. **coding_suite** - 编程任务工具集
4. **file_operations** - 文件操作工具集
5. **debugging_tools** - 调试工具集

## 智能功能

### 自动选择功能
`mcp_servers` 工具组具有智能自动选择功能：
- **关键词识别**：根据用户输入自动识别需求
- **工具推荐**：按相关度排序显示可用工具
- **自动执行**：高置信度时自动执行推荐工具

### 关键词触发
为每个工具配置了相关关键词：
- **文档相关**：documentation, docs, API, library, 文档, 说明书
- **网页相关**：crawl, scrape, webpage, website, 爬取, 网页
- **编辑器相关**：editor, neovim, vim, buffer, 编辑器, 缓冲区
- **GitHub 相关**：github, repository, repo, git, 仓库, 代码库
- **文件系统相关**：filesystem, file, directory, 文件系统, 文件, 目录

## 使用方式

### 1. 直接使用最终配置
```lua
-- 在 init.lua 或配置文件中
local interactions = require("plugins.CodeCompanion_mcp.interactions_final")
require("codecompanion").setup({
  interactions = interactions.config
})
```

### 2. 动态添加 MCP 工具
```lua
-- 如果需要动态控制
local base_config = require("plugins.CodeCompanion_mcp.interactions_base").config
local mcp_tools = require("plugins.CodeCompanion_mcp.add_mcp_tools")

-- 根据需要添加 MCP 工具
local final_config = mcp_tools.add_mcp_tools_to_config(base_config)
```

### 3. 测试配置
```lua
-- 运行测试验证配置
local mcp_tools = require("plugins.CodeCompanion_mcp.add_mcp_tools")
mcp_tools.test_mcp_tools_addition()
```

## 在聊天中使用

### 调用单个工具
```markdown
使用 @{context7} 获取 React 文档
使用 @{crawl4ai} 爬取 https://example.com
使用 @{github} 查看我的仓库
```

### 使用工具组
```markdown
@{mcp_servers} 帮我查找最新的前端框架
@{web_tools} 研究最新的 AI 技术
@{coding_suite} 帮我重构代码
```

### 智能自动选择
```markdown
我需要查看 Python 的文档和示例
-- 自动建议: @{mcp_servers} (包含 context7)
```

## 配置更新

### 添加新的 MCP 工具
1. 在 `mcp.lua` 中添加服务器配置
2. 在 `mcp_tools_config.lua` 中添加工具定义
3. 在相应的工具组中添加工具引用

### 修改工具行为
1. 在 `mcp_tools_config.lua` 中修改工具配置
2. 更新关键词、优先级等参数
3. 重新加载配置

## 故障排除

### 常见问题
1. **工具未找到**：检查工具名称是否正确，确保在配置中定义
2. **回调错误**：确保 `custom_mcp_tools.lua` 扩展正确加载
3. **关键词不触发**：检查关键词配置，确保包含相关词汇

### 测试步骤
1. 运行 `test_mcp_tools_addition()` 验证配置
2. 检查系统提示是否包含 MCP 工具说明
3. 在聊天中测试工具调用

## 优势

### 模块化设计
- 基础配置和 MCP 配置分离
- 易于维护和更新
- 可重用组件

### 智能集成
- 自动工具选择
- 关键词触发机制
- 优先级管理

### 完整功能
- 支持所有 MCP 服务器
- 完整的工具组配置
- 详细的系统提示

## 下一步

1. **实际测试**：在 Neovim 中测试 MCP 工具的实际使用
2. **性能优化**：根据使用情况调整配置
3. **功能扩展**：添加更多 MCP 服务器和工具
4. **用户反馈**：收集使用体验，优化配置