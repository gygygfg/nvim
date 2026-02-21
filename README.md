# Neovim 配置

这是一个现代化的 Neovim 配置，基于 Lua 编写，使用 lazy.nvim 作为插件管理器。

## ✨ 特性

- **快速启动**: 使用 lazy.nvim 实现按需加载，启动速度快
- **模块化设计**: 配置按功能模块组织，易于维护和扩展
- **现代插件**: 集成最新的 Neovim 插件生态系统
- **MCP 支持**: 内置 Model Context Protocol 服务器支持
- **多语言支持**: 支持多种编程语言的开发环境

## 📁 项目结构

```
.
├── init.lua              # 主配置文件
├── lazy-lock.json        # 插件锁定文件
├── lua/                  # Lua 配置模块
│   ├── keymaps.lua      # 快捷键配置
│   ├── nvim_venv.lua    # Python 虚拟环境配置
│   └── plugins/         # 插件配置
└── mcp/                  # MCP 服务器配置
    ├── servers.json     # MCP 服务器列表
    └── tools/           # MCP 工具脚本
```

## 🚀 快速开始

### 前提条件

- Neovim 0.11.6 或更高版本
- Git
- 可选: Python 3.8+ (用于某些插件)

### 安装

1. **备份现有配置** (如果已有):
   ```bash
   mv ~/.config/nvim ~/.config/nvim.backup
   ```

2. **克隆此配置**:
   ```bash
   git clone https://github.com/yourusername/nvim-config ~/.config/nvim
   ```

3. **启动 Neovim**:
   ```bash
   nvim
   ```
   首次启动时会自动安装 lazy.nvim 和所有插件。

## ⚙️ 配置

### 自定义配置

配置采用模块化设计，可以轻松自定义：

- **添加新插件**: 在 `lua/plugins/` 目录下创建新的 Lua 文件
- **修改快捷键**: 编辑 `lua/keymaps.lua`
- **调整主题**: 修改 `lua/plugins/colorscheme.lua` (如果存在)

### MCP 配置

MCP (Model Context Protocol) 服务器配置位于 `mcp/` 目录：

- `mcp/servers.json`: MCP 服务器定义
- `mcp/tools/`: 自定义 MCP 工具脚本

## 🔌 主要插件

- **插件管理器**: [lazy.nvim](https://github.com/folke/lazy.nvim)
- **文件浏览**: [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)
- **状态栏**: [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
- **语法高亮**: [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- **自动补全**: [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
- **LSP**: [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- **代码格式化**: [conform.nvim](https://github.com/stevearc/conform.nvim)

## 🎨 主题

默认使用 [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) 主题，支持亮色和暗色模式。

## ⌨️ 常用快捷键

### 导航
- `<leader>e`: 打开文件浏览器
- `<C-h/j/k/l>`: 在窗口间导航
- `<leader>ff`: 查找文件
- `<leader>fg`: 实时 grep

### 编辑
- `gd`: 跳转到定义
- `gr`: 查找引用
- `<leader>ca`: 代码操作
- `<leader>rn`: 重命名符号

### Git
- `<leader>gg`: 打开 lazygit
- `<leader>gs`: 显示 git 状态

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 🙏 致谢

感谢所有插件开发者和 Neovim 社区的贡献者。