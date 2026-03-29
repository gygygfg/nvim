# MCP Hub 故障排除指南

## 常见问题及解决方案

### 1. 变量描述换行符错误

**症状：**
重启 Neovim 后，在聊天中按 `?` 出现错误：
```
E5108: Error executing lua: ...utils/ui.lua:32: 'replacement string' item contains newlines
```

**原因：**
MCP Hub v4 将 MCP 资源转换为聊天变量，某些变量描述包含换行符。

**解决方案：**

1. **更新 MCP Hub 到最新版本**
   ```bash
   # 通过包管理器更新
   :Lazy update
   ```

2. **MCP Hub 已修复此问题**，移除了变量描述中的换行符

**临时解决步骤：**
1. 启动 Neovim
2. 启动 MCP Hub 并切换 Neovim 原生服务器
3. 启动 CodeCompanionChat
4. 按 `?` 查看快捷键绑定

### 2. MCP 服务器连接失败

**症状：**
- 工具调用返回 "服务器未连接" 错误
- MCP Hub UI 显示服务器离线状态

**解决方案：**

1. **检查服务器配置：**
   ```lua
   -- 查看服务器配置
   :lua require("mcphub").get_servers()
   ```

2. **重启 MCP Hub：**
   ```lua
   :lua require("mcphub").restart()
   ```

3. **检查服务器日志：**
   ```bash
   # 查看 MCP Hub 日志
   tail -f ~/.local/state/nvim/mcphub.log
   ```

4. **验证服务器命令：**
   ```bash
   # 手动测试服务器命令
   npx @modelcontextprotocol/server-github --help
   ```

### 3. 工具无法自动触发

**症状：**
- 相关关键词未触发 MCP 工具
- 需要手动指定工具名称

**解决方案：**

1. **检查自动触发配置：**
   ```lua
   -- 确保 auto_trigger 已启用
   make_tools = true,
   show_server_tools_in_chat = true,
   ```

2. **验证关键词配置：**
   ```lua
   -- 检查服务器配置中的关键词
   auto_trigger_keywords = {
     "crawl", "scrape", "extract", "webpage",
     "documentation", "docs", "API", "library"
   }
   ```

3. **重新加载配置：**
   ```lua
   :lua require("codecompanion").setup()
   ```

### 4. 权限和自动批准问题

**症状：**
- 每次调用工具都需要手动批准
- 某些工具被错误地阻止

**解决方案：**

1. **检查自动批准配置：**
   ```lua
   -- 查看当前自动批准设置
   :lua require("plugins.CodeCompanion_mcp.config.mcphub_auto_approve").get_config()
   ```

2. **启用自动工具模式：**
   ```lua
   -- 临时启用自动批准
   :lua require("plugins.CodeCompanion_mcp.config.mcphub_auto_approve").set_auto_approve_mode(true)
   ```

3. **配置函数式自动批准：**
   ```lua
   -- 在 mcphub_integration.lua 中调整自动批准规则
   auto_approve_function = function(params)
     -- 添加自定义规则
   end
   ```

### 5. 性能问题

**症状：**
- 工具响应缓慢
- 聊天界面卡顿

**解决方案：**

1. **优化服务器优先级：**
   ```lua
   -- 调整服务器优先级
   priority = 1, -- 高优先级服务器
   priority = 5, -- 低优先级服务器
   ```

2. **禁用不必要的服务器：**
   ```lua
   -- 在服务器配置中禁用
   enabled = false,
   ```

3. **限制并发请求：**
   ```lua
   -- 在 MCP Hub 配置中添加
   max_concurrent_requests = 3,
   ```

### 6. 资源变量无法使用

**症状：**
- `#{mcp:...}` 变量无法解析
- 资源变量显示为普通文本

**解决方案：**

1. **检查资源配置：**
   ```lua
   -- 确保 make_vars 已启用
   make_vars = true,
   ```

2. **验证资源路径：**
   ```lua
   -- 正确的资源变量格式
   #{mcp:neovim://diagnostics/buffer}
   #{mcp:filesystem://current_directory}
   ```

3. **重新加载 MCP 资源：**
   ```lua
   :lua require("mcphub").refresh_resources()
   ```

### 7. 斜杠命令无法使用

**症状：**
- `/mcp:` 命令未显示在补全中
- 斜杠命令执行失败

**解决方案：**

1. **检查斜杠命令配置：**
   ```lua
   -- 确保 make_slash_commands 已启用
   make_slash_commands = true,
   ```

2. **重新加载提示词：**
   ```lua
   :lua require("mcphub").reload_prompts()
   ```

3. **查看可用命令：**
   ```lua
   -- 在聊天中按 / 查看所有可用命令
   ```

### 8. 自定义工具组无法访问

**症状：**
- `@{group_name}` 工具组未找到
- 自定义工具组中的工具无法使用

**解决方案：**

1. **检查工具组配置：**
   ```lua
   -- 验证工具组定义
   groups = {
     ["github_pr_workflow"] = {
       description = "从 issue 到 PR 的 GitHub 操作流程",
       tools = { ... }
     }
   }
   ```

2. **重新加载工具配置：**
   ```lua
   :lua require("codecompanion").setup()
   ```

3. **查看可用工具组：**
   ```lua
   -- 在聊天中按 @ 查看所有可用工具组
   ```

## 调试技巧

### 1. 启用详细日志
```lua
-- 在 CodeCompanion 配置中
log_level = "DEBUG",
```

### 2. 检查 MCP Hub 状态
```lua
:lua print(vim.inspect(require("mcphub").status()))
```

### 3. 测试单个工具
```lua
:lua require("mcphub").call_tool("neovim__read_file", {path = "init.lua"})
```

### 4. 查看系统提示词
```lua
:lua print(require("plugins.CodeCompanion_mcp.config.mcphub_integration").get_mcphub_system_prompt())
```

## 最佳实践

1. **逐步启用功能**：先启用 `make_tools = true`，熟悉后再添加其他功能
2. **定期更新**：保持 MCP Hub 和 CodeCompanion 为最新版本
3. **备份配置**：在修改配置前备份现有配置
4. **测试工作流**：在重要任务前测试相关工具链
5. **查看日志**：遇到问题时首先查看相关日志

## 获取帮助

1. **MCP Hub 文档**：访问 `http://localhost:3000`（默认管理界面）
2. **CodeCompanion 文档**：`:help codecompanion`
3. **GitHub Issues**：在插件仓库报告问题
4. **社区支持**：加入相关 Discord 或论坛获取帮助