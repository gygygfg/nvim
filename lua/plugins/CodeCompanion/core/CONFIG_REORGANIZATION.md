# CodeCompanion 配置重构说明

## 重构目的
将 `interactions_base.lua` 中多余的配置移动到相应的 `display.lua` 和 `adapters.lua` 文件中，使配置结构更加清晰和模块化。

## 重构内容

### 1. 从 `interactions_base.lua` 移动到 `display.lua` 的配置

#### 显示相关选项：
- **聊天显示选项** (`chat.opts`):
  - `blank_prompt`: 用户未提供提示时使用的提示
  - `debounce`: 用户输入去抖动时间（毫秒）
  - `wait_timeout`: 超时前等待用户响应的时间（毫秒）
  - `yank_jump_delay_ms`: 从复制的代码跳回前的延迟（毫秒）
  - `auto_scroll`: 自动滚动
  - `show_reasoning`: 显示推理内容
  - `acp_timeout_response`: ACP 权限请求超时处理方式

- **内联显示选项** (`inline.opts`):
  - `diff_show_simple_prompt`: 显示简单提示
  - `diff_default_action`: 默认操作
  - `diff_prompt_text`: 提示文本

- **共享键位映射** (`shared.keymaps`):
  - `view_diff`: 查看建议的差异
  - `always_accept`: 始终接受此缓冲区中的更改
  - `accept_change`: 接受更改
  - `reject_change`: 拒绝更改
  - `cancel`: 取消所有待处理的工具调用
  - `next_hunk`: 转到下一个差异块
  - `previous_hunk`: 转到上一个差异块

### 2. 从 `interactions_base.lua` 移动到 `adapters.lua` 的配置

#### 适配器配置：
- **聊天适配器** (`chat.adapter`):
  - `name`: "deepseek"
  - `model`: "deepseek-chat"

- **内联适配器** (`inline.adapter`):
  - `name`: "deepseek"
  - `model`: "deepseek-code"

- **命令适配器** (`cmd.adapter`):
  - `name`: "step"
  - `model`: "step-3.5-flash"

- **后台适配器** (`background.adapter`):
  - `name`: "deepseek"
  - `model`: "deepseek-chat"
  - `enabled`: true

### 3. 保留在 `interactions_base.lua` 的配置

#### 核心交互配置：
- **提示词模板** (`PROMPT_TEMPLATES`):
  - `AGENT_SYSTEM_PROMPT`: 代理组系统提示词
  - `TOOL_SYSTEM_PROMPT`: 工具系统提示词
  - `ADDITIONAL_CONTEXT_TEMPLATE`: 附加上下文模板

- **工具配置** (`tools`):
  - 工具组配置 (`groups`): agent, files
  - 单个工具配置: ask_questions, create_file, delete_file 等
  - 工具选项: auto_submit_errors, folds, default_tools 等

- **斜杠命令** (`slash_commands`):
  - buffer, command, compact, fetch, quickfix, file, help, image, rules, now, symbols, terminal, mcp, resume

- **编辑器上下文** (`editor_context`):
  - buffer, lsp, viewport

- **系统提示词函数** (`system_prompt`):
  - 聊天系统提示词生成函数

## 配置结构对比

### 重构前：
```
interactions_base.lua
├── 提示词模板
├── 适配器配置
├── 工具配置
├── 斜杠命令
├── 显示选项
├── 键位映射
└── 编辑器上下文
```

### 重构后：
```
interactions_base.lua    - 核心交互逻辑
├── 提示词模板
├── 工具配置
├── 斜杠命令
├── 系统提示词函数
└── 编辑器上下文

display.lua             - 显示相关配置
├── 动作面板
├── 聊天显示
├── 内联显示
├── 差异显示
├── 输入配置
├── 共享键位映射
└── 显示选项

adapters.lua           - 适配器配置
├── HTTP 适配器 (deepseek, step)
├── ACP 适配器 (opencode)
├── 聊天适配器
├── 内联适配器
├── 命令适配器
└── 后台适配器
```

## 使用说明

### 1. 修改显示配置
现在所有显示相关的配置都在 `display.lua` 中：
```lua
-- 修改聊天窗口大小
M.config.chat.window.width = 0.6

-- 修改内联显示选项
M.config.inline.opts.diff_default_action = "preview"
```

### 2. 修改适配器配置
现在所有适配器相关的配置都在 `adapters.lua` 中：
```lua
-- 修改聊天适配器
M.config.chat.adapter.name = "openai"
M.config.chat.adapter.model = "gpt-4"

-- 添加新的 HTTP 适配器
M.config.http.new_adapter = function()
  return require("codecompanion.adapters").extend("openai_compatible", {
    name = "new_adapter",
    -- 配置...
  })
end
```

### 3. 修改交互配置
核心交互配置仍在 `interactions_base.lua` 中：
```lua
-- 添加新工具
M.config.chat.tools["new_tool"] = {
  path = "interactions.chat.tools.builtin.new_tool",
  description = "新工具描述",
}

-- 修改提示词模板
PROMPT_TEMPLATES.AGENT_SYSTEM_PROMPT = [[新的提示词...]]
```

## 注意事项

1. **向后兼容性**: 重构后的配置结构需要相应的代码调整来读取新的配置位置
2. **配置引用**: 插件代码需要更新以从正确的位置读取配置
3. **模块化**: 新的结构使配置更加模块化，便于维护和扩展

## 下一步

1. 更新插件代码以使用新的配置结构
2. 测试所有功能确保正常工作
3. 更新文档说明新的配置方式