# CodeCompanion MCP 集成插件目录结构

## 整理后的结构

```
CodeCompanion_mcp/
├── init.lua                    # 插件主入口
├── STRUCTURE.md               # 本文件 - 目录结构说明
├── core/                      # 核心模块
│   ├── adapters.lua          # 适配器配置
│   ├── display.lua           # 显示配置
│   └── interactions_base.lua # 基础交互策略
├── config/                    # 配置文件
│   ├── config.lua            # 主配置函数
│   └── mcp_tools_config.lua  # MCP工具配置
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
│   └── 工具组测试报告.md
├── extensions/               # 扩展文件
│   ├── mcphub.lua           # MCP Hub扩展
│   └── custom_mcp_tools.lua # 自定义MCP工具
└── interactions.lua         # 主交互策略文件（独立）
```

## 模块功能说明

### 核心模块 (core/)
- **adapters.lua**: 定义与不同AI服务的适配器配置
- **display.lua**: 控制CodeCompanion的界面显示和窗口管理
- **interactions_base.lua**: 提供基础的交互策略和工具定义

### 配置文件 (config/)
- **config.lua**: 包含全屏切换等配置函数
- **mcp_tools_config.lua**: 配置MCP工具的使用策略和参数

### MCP模块 (mcp/)
- **mcp.lua**: 定义MCP服务器配置和启用状态
- **mcp_integration.lua**: 提供MCP服务器状态检查和测试功能
- **interactions_with_mcp.lua**: 专门为MCP集成设计的交互策略

### 文档文件 (docs/)
包含所有Markdown格式的文档，包括使用指南、集成说明和测试报告。

### 扩展文件 (extensions/)
包含CodeCompanion的扩展功能，特别是与MCP Hub的集成。

### 独立文件
- **init.lua**: 插件入口，加载所有模块
- **interactions.lua**: 主交互策略，定义AI助手的系统提示和工具使用策略

## 依赖关系

```
init.lua
├── core/adapters.lua
├── core/display.lua
└── mcp/interactions_with_mcp.lua

mcp/mcp_integration.lua
└── mcp/mcp.lua

interactions.lua (独立，不依赖其他模块)
```

## 使用说明

1. **插件初始化**: `init.lua` 加载所有配置模块
2. **MCP集成**: 通过 `mcp/` 目录下的文件管理MCP服务器
3. **配置调整**: 修改 `config/` 目录下的文件调整插件行为
4. **扩展功能**: `extensions/` 目录包含额外的功能扩展

## 维护建议

- 新增核心功能应放在 `core/` 目录
- 新增MCP相关功能应放在 `mcp/` 目录
- 新增配置选项应放在 `config/` 目录
- 新增文档应放在 `docs/` 目录
- 新增扩展应放在 `extensions/` 目录