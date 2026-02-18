# CodeCompanion MCP 集成插件 - 整理后的结构

## 📁 新的目录结构

```
CodeCompanion_mcp/
├── init.lua                    # 插件主入口
├── STRUCTURE.md               # 详细目录结构说明
├── README_NEW_STRUCTURE.md    # 本文件
├── core/                      # 核心模块
│   ├── adapters.lua          # 适配器配置
│   ├── display.lua           # 显示配置
│   └── interactions_base.lua # 基础交互策略
├── config/                    # 配置文件
│   ├── config.lua            # 主配置函数
│   ├── mcp_tools_config_fixed.lua  # MCP工具配置
│   ├── mcphub_integration.lua      # MCP Hub完整集成配置
│   └── mcphub_auto_approve.lua     # MCP Hub自动批准配置
├── mcp/                      # MCP相关模块
│   ├── mcp.lua              # MCP基础配置
│   ├── mcp_integration.lua  # MCP集成模块
│   └── interactions_with_mcp.lua # MCP集成交互策略
├── docs/                     # 文档文件
│   ├── README.md            # 主README
│   ├── README_MCP_INTEGRATION.md
│   ├── MCP_TOOLS_SETUP_GUIDE.md
│   ├── MCP_SERVERS_USAGE_GUIDE.md
│   ├── MCP_TOOLS_INTEGRATION_SUMMARY.md
│   ├── MCP_TOOLS_USAGE.md
│   ├── USAGE_EXAMPLE.md
│   ├── FINAL_SUMMARY.md
│   ├── react_usestate_hook_docs.md
│   ├── 工具组测试报告.md
│   ├── mcphub_troubleshooting.md  # MCP Hub故障排除
│   └── mcphub_quickstart.md       # MCP Hub快速启动
├── extensions/               # 扩展文件
│   ├── mcphub.lua           # MCP Hub扩展
│   └── custom_mcp_tools.lua # 自定义MCP工具
├── examples/                 # 使用示例
│   └── mcphub_usage_examples.lua # MCP Hub使用示例
└── interactions.lua         # 主交互策略文件（独立）
```

## 🔄 整理变化

### 移动的文件：
1. **核心模块** → `core/` 目录
   - `adapters.lua`
   - `display.lua`
   - `interactions_base.lua`

2. **配置文件** → `config/` 目录
   - `config.lua`
   - `mcp_tools_config.lua`

3. **MCP模块** → `mcp/` 目录
   - `mcp.lua`
   - `mcp_integration.lua`
   - `interactions_with_mcp.lua`

4. **文档文件** → `docs/` 目录
   - 所有 `.md` 文件

5. **扩展文件** → `extensions/` 目录
   - `mcphub.lua`
   - `custom_mcp_tools.lua`

### 保持不变的文件：
- `init.lua` - 插件入口（已更新导入路径）
- `interactions.lua` - 主交互策略

### 删除的文件：
- `interactions.lua.backup` - 备份文件

## 📝 更新说明

### `init.lua` 中的路径更新：
```lua
-- 之前：
local adapters = require("plugins.CodeCompanion_mcp.adapters")
local interactions_with_mcp = require("plugins.CodeCompanion_mcp.interactions_with_mcp")
local display = require("plugins.CodeCompanion_mcp.display")

-- 之后：
local adapters = require("plugins.CodeCompanion_mcp.core.adapters")
local interactions_with_mcp = require("plugins.CodeCompanion_mcp.mcp.interactions_with_mcp")
local display = require("plugins.CodeCompanion_mcp.core.display")
```

## 🎯 整理优势

1. **逻辑清晰**：功能相近的模块放在一起
2. **易于维护**：相关文件集中管理
3. **扩展方便**：新增功能可以放在合适的目录
4. **文档集中**：所有文档统一管理
5. **结构标准**：符合常见的插件目录结构

## 🚀 使用建议

1. **新增核心功能** → 放在 `core/` 目录
2. **新增配置选项** → 放在 `config/` 目录
3. **新增MCP功能** → 放在 `mcp/` 目录
4. **新增文档** → 放在 `docs/` 目录
5. **新增扩展** → 放在 `extensions/` 目录

## 📊 文件统计

- 总文件数：23个
- Lua文件：11个
- Markdown文件：12个
- 目录数：6个

整理完成！现在文件夹结构更加清晰，便于管理和维护。

## 🔧 MCP Hub 完整集成

### 新增的 MCP Hub 功能

#### 1. 完整集成配置 (`config/mcphub_integration.lua`)
- MCP Hub 扩展配置
- 自定义工具组配置
- 自动批准配置
- 系统提示词集成

#### 2. 自动批准管理 (`config/mcphub_auto_approve.lua`)
- 工具自动批准规则
- 函数式自动批准
- 批准状态管理

#### 3. 使用示例 (`examples/mcphub_usage_examples.lua`)
- 通用 MCP 访问示例
- 服务器组访问示例
- 独立工具访问示例
- 完整工作流示例

#### 4. 文档支持 (`docs/`)
- `mcphub_troubleshooting.md` - 故障排除指南
- `mcphub_quickstart.md` - 快速启动指南

### MCP Hub 核心特性

#### 工具访问的四种模式：
1. **通用 MCP 访问** (`@{mcp}`) - 所有可用 MCP 服务器
2. **服务器组访问** (`@{neovim}`, `@{github}`) - 特定服务器所有工具
3. **独立工具访问** (`@{neovim__read_file}`) - 精细控制单个工具
4. **自定义工具组** (`@{github_pr_workflow}`) - 预定义工作流

#### 高级功能：
- **资源变量**: `#{mcp:neovim://diagnostics/buffer}`
- **斜杠命令**: `/mcp:code_review`, `/mcp:explain_function`
- **自动批准**: 函数式自动批准规则
- **自定义工作流**: GitHub PR 工作流、网页研究工作流等

### 快速测试命令

```lua
-- 测试 MCP Hub 集成
:lua require("plugins.CodeCompanion_mcp.config.mcphub_integration").get_full_config()

-- 测试自动批准
:lua require("plugins.CodeCompanion_mcp.config.mcphub_auto_approve").toggle_auto_approve_mode()

-- 查看使用示例
:lua require("plugins.CodeCompanion_mcp.examples.mcphub_usage_examples").print_example_menu()
```

### 故障排除

如果遇到变量描述换行符错误：
1. 更新 MCP Hub 到最新版本
2. 按顺序启动：Neovim → MCP Hub → CodeCompanionChat
3. 按 `?` 查看快捷键绑定

### 最佳实践
1. 逐步启用功能：先 `make_tools = true`，再添加其他功能
2. 安全配置：使用函数式自动批准，避免全局自动批准
3. 工具发现：使用 MCP Hub UI 或工具补全来发现可用工具
4. 自定义工作流：根据项目需求创建自定义工具组

现在您的 CodeCompanion 已完全集成 MCP Hub，可以充分利用 MCP 生态系统的各种工具提升开发效率！