# MCP Hub 快速启动指南

## 1. 安装验证

### 检查插件安装
```lua
-- 验证插件已安装
:checkhealth codecompanion
:checkhealth mcphub
```

### 验证 MCP Hub 运行状态
```bash
# 检查 MCP Hub 进程
ps aux | grep mcp-hub

# 访问管理界面
# 默认地址: http://localhost:3000
# 默认凭据: admin/admin123
```

## 2. 基本配置

### 最小配置示例
```lua
-- init.lua 中的最小配置
require("codecompanion").setup({
    extensions = {
    mcphub = {
    callback = "mcphub.extensions.codecompanion",
    opts = {
    make_tools = true,
    show_server_tools_in_chat = true,
    make_vars = true,
    make_slash_commands = true,
    }
    }
    }
    })
```

### 验证配置生效
```lua
-- 检查 MCP 工具是否可用
:lua print(vim.inspect(require("codecompanion").get_tools()))
```

## 3. 快速测试

### 测试 1: 读取文件
```
@{neovim__read_file} 显示当前文件内容
```

### 测试 2: 网页获取
```
@{crawl4ai__crawl} 获取 https://example.com 的内容
```

### 测试 3: 文档搜索
```
@{context7__search} 搜索关于 "neovim lua" 的文档
```

### 测试 4: 资源变量
```
分析当前缓冲区 #{mcp:neovim:buffer}
```

## 4. 常用工具速查

### Neovim 工具
- `@{neovim__read_file}` - 读取文件内容
- `@{neovim__write_file}` - 写入文件
- `@{neovim__edit_file}` - 编辑文件
- `@{neovim__get_diagnostics}` - 获取诊断信息

### 文件系统工具
- `@{filesystem__read_file}` - 读取文件
- `@{filesystem__list_files}` - 列出文件
- `@{filesystem__write_file}` - 写入文件

### GitHub 工具
- `@{github__get_issue}` - 获取 issue
- `@{github__list_issues}` - 列出 issues
- `@{github__create_issue}` - 创建 issue
- `@{github__create_pull_request}` - 创建 PR

### 网页工具
- `@{crawl4ai__crawl}` - 爬取网页
- `@{crawl4ai__extract}` - 提取内容
- `@{crawl4ai__summarize}` - 生成摘要

### 文档工具
- `@{context7__search}` - 搜索文档
- `@{context7__query}` - 查询文档

## 5. 常用工作流

### 代码审查工作流
```
/mcp:code_review 审查当前文件
#{mcp:neovim://diagnostics/buffer} 检查问题
@{neovim__edit_file} 修复发现的问题
```

### 文档生成工作流
```
@{filesystem__list_files} 列出项目文件
@{context7__search} 搜索相关文档
/mcp:generate_documentation 生成项目文档
```

### Issue 处理工作流
```
@{github__get_issue} 获取 issue 详情
@{neovim__read_file} 读取相关代码
@{neovim__edit_file} 修复问题
@{github__create_pull_request} 创建 PR
```

## 6. 快捷键参考

### 聊天界面快捷键
- `?` - 显示帮助（检查变量描述问题）
- `@` - 显示可用工具组
- `/` - 显示斜杠命令
- `Tab` - 工具名称补全

### 自动批准控制
```lua
-- 启用自动批准模式
:lua require("plugins.CodeCompanion_mcp.config.mcphub_auto_approve").set_auto_approve_mode(true)

-- 禁用自动批准模式
:lua require("plugins.CodeCompanion_mcp.config.mcphub_auto_approve").set_auto_approve_mode(false)

-- 切换模式
:lua require("plugins.CodeCompanion_mcp.config.mcphub_auto_approve").toggle_auto_approve_mode()
```

## 7. 故障快速排查

### 问题: 工具无法调用
1. 检查 MCP Hub 状态: `:lua require("mcphub").status()`
2. 验证服务器连接: 访问 http://localhost:3000
3. 查看日志: `:messages`

### 问题: 变量描述错误
1. 更新 MCP Hub: `:Lazy update`
2. 重启 Neovim
3. 按步骤启动: Neovim → MCP Hub → CodeCompanionChat → 按 `?`

### 问题: 性能缓慢
1. 禁用不必要的服务器
2. 调整服务器优先级
3. 限制并发请求

## 8. 下一步学习

### 深入学习
1. 查看完整配置: `config/mcphub_integration.lua`
3. 阅读故障排除: `docs/mcphub_troubleshooting.md`

### 高级功能
1. 自定义工具组
2. 函数式自动批准
3. 资源变量高级用法
4. 斜杠命令自定义

### 扩展集成
1. 添加新的 MCP 服务器
2. 创建自定义工作流
3. 集成其他开发工具

## 9. 获取帮助

### 在线资源
- MCP Hub 文档: http://localhost:3000
- CodeCompanion 文档: `:help codecompanion`
- MCP 协议文档: https://spec.modelcontextprotocol.io

### 社区支持
- GitHub Issues
- Neovim 社区
- Discord 频道

---

**提示**: 开始使用时，建议先启用 `make_tools = true`，熟悉基本工具后再逐步启用 `make_vars` 和 `make_slash_commands` 功能。
