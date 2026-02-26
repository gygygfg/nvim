# Neovim 配置

这是一个现代化的 Neovim 配置，基于 Lua 编写，使用 lazy.nvim 作为插件管理器，特别集成了 CodeCompanion MCP 功能。

## ✨ 特性

- **快速启动**: 使用 lazy.nvim 实现按需加载，启动速度快
- **模块化设计**: 配置按功能模块组织，易于维护和扩展
- **AI 助手集成**: 内置 CodeCompanion MCP 支持，提供智能代码补全和对话功能
- **多语言开发**: 支持 Python、JavaScript/TypeScript、Go、Rust 等多种编程语言
- **现代化工具链**: 集成 LSP、Treesitter 等现代开发工具
- **智能环境管理**: 自动检测和管理 Python 虚拟环境、Node.js 版本
- **美观界面**: 现代化 UI 组件和主题，提供优秀的视觉体验

## 📁 项目结构

```
.
├── init.lua                      # 主配置文件
├── lazy-lock.json                # 插件锁定文件
├── lua/                          # Lua 配置模块
│   ├── keymaps.lua              # 快捷键配置
│   ├── local_conf.lua           # 本地个性化配置
│   ├── nvm_init.lua             # Node.js 版本管理
│   ├── python_venv.lua          # Python 虚拟环境管理
│   └── plugins/                 # 插件配置目录
│       ├── CodeCompanion_mcp/   # CodeCompanion MCP 集成
│       ├── lsp/                 # LSP 配置
│       ├── git/                 # Git 相关插件
│       ├── nvim-tree.lua       # 文件浏览器
│       ├── nvim-treesitter.lua # 语法高亮
│       ├── lualine.lua         # 状态栏
│       ├── bufferline.lua      # 标签栏
│       ├── toggleterm.lua      # 终端集成
│       ├── code_runner.lua     # 代码运行器
│       ├── vim-translator.lua  # 翻译工具
│       └── ... 其他插件配置
└── README.md                    # 项目说明文档
```

## 🚀 快速开始

### 前提条件

- **Neovim 0.11.6 或更高版本**
  - **Git**
  - **Python 3.8+** (用于 Python 开发环境和某些插件)
  - **Node.js 18+** (用于 JavaScript/TypeScript 开发)
  - **Rust 工具链** (可选，用于 Rust 开发)
- **Go 1.20+** (可选，用于 Go 开发)

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
       首次启动时会自动安装 lazy.nvim 和所有插件，这可能需要几分钟时间。

       4. **安装语言服务器** (可选):
         启动 Neovim 后，运行 `:Mason` 命令安装所需的语言服务器。

## ⚙️ 配置

### 自定义配置

         配置采用模块化设计，可以轻松自定义：

         - **添加新插件**: 在 `lua/plugins/` 目录下创建新的 Lua 文件
         - **修改快捷键**: 编辑 `lua/keymaps.lua`
         - **调整主题**: 修改 `lua/plugins/iceberg.lua` (当前使用 iceberg 主题)
         - **本地个性化**: 编辑 `lua/local_conf.lua` 进行个性化设置

### 环境管理

         - **Python 虚拟环境**: 自动检测和激活项目中的虚拟环境
         - **Node.js 版本**: 通过 nvm_init.lua 管理 Node.js 版本
         - **语言服务器**: 通过 Mason 管理语言服务器安装

### CodeCompanion MCP 配置

         本配置深度集成了 CodeCompanion MCP 功能，提供 AI 助手支持：

         - **智能对话**: 通过 `<leader>cc` 打开 AI 对话界面
         - **代码补全**: 智能代码建议和补全
         - **代码审查**: 对选中的代码进行审查和建议
         - **MCP 工具**: 支持多种 MCP 工具调用

## 🔌 主要插件

### 核心插件
         - **插件管理器**: [lazy.nvim](https://github.com/folke/lazy.nvim)
         - **AI 助手**: [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim) + MCP 集成
         - **MCP 管理**: [mcphub.nvim](https://github.com/ravitemer/mcphub.nvim)

### 界面插件
         - **文件浏览**: [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)
         - **状态栏**: [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
         - **标签栏**: [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
         - **语法高亮**: [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
         - **主题**: [iceberg.vim](https://github.com/cocopon/iceberg.vim)

### 开发工具
         - **自动补全**: [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
         - **LSP**: [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) + [mason.nvim](https://github.com/williamboman/mason.nvim)
         - **代码折叠**: [ufo.nvim](https://github.com/kevinhwang91/ufo.nvim)
         - **终端**: [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)
         - **代码运行**: [code_runner.nvim](https://github.com/CRAG666/code_runner.nvim)

### 辅助工具
         - **翻译**: [vim-translator](https://github.com/voldikss/vim-translator)
         - **快速跳转**: [hop.nvim](https://github.com/phaazon/hop.nvim)
         - **注释**: [nvim-comment](https://github.com/terrortylor/nvim-comment)
         - **Git**: [vim-fugitive](https://github.com/tpope/vim-fugitive)

## 🎨 主题

         默认使用 [iceberg.vim](https://github.com/cocopon/iceberg.vim) 主题，这是一个优雅的蓝灰色主题，支持亮色和暗色模式。

## ⌨️ 常用快捷键

### 基础快捷键
         - `<leader>`: 空格键 (Space)
         - `<C-s>`: 保存文件 (Normal/Insert 模式)
         - `<leader>h`: 取消搜索高亮

### 导航
         - `<leader>d`: 打开/关闭文件浏览器 (nvim-tree)
         - `<C-h/j/k/l>`: 在窗口间导航
         - `gh`: 显示悬停文档
         - `g[`/`g]`: 跳转到上一个/下一个诊断

### 代码操作
         - `gd`: 跳转到定义
         - `gr`: 查找引用
         - `<leader>ca`: 代码操作菜单
         - `<leader>rn`: 重命名符号
         - `K`: 显示悬停信息

### LSP 相关
         - `go`: 打开诊断浮窗
         - `<leader>q`: 显示诊断列表
         - `<leader>wl`: 查看工作区文件夹

### 终端
         - `<leader>t`: 打开浮动终端
         - `<C-t>`: (Insert 模式) 保存并打开终端

### 代码运行
         - `<leader>r`: 运行当前代码
         - `<leader>rc`: 关闭代码运行窗口

### 翻译工具
         - `ti`: 打开翻译输入框
         - `ty`: 翻译剪贴板内容
         - `tc`: 翻译光标处单词
         - `tv`: (Visual 模式) 翻译选中文本
         - `tr`: (Visual 模式) 替换为翻译

### CodeCompanion AI 助手
         - `<leader>cc`: 打开 CodeCompanion 聊天界面
         - `<leader>cp`: (Visual 模式) 对选中代码执行 AI 动作

### 其他工具
         - `<leader>l`: 切换注释
         - `zR`/`zM`: 展开/折叠所有代码块 (ufo)

## 🤝 贡献

         欢迎提交 Issue 和 Pull Request！

### 开发指南
  1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
  3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
  5. 打开 Pull Request

## 📄 许可证

  MIT License - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

  感谢所有插件开发者和 Neovim 社区的贡献者，特别感谢：

  - **Neovim 团队**: 创造了这个优秀的编辑器
  - **lazy.nvim 作者**: 提供了优秀的插件管理器
  - **CodeCompanion 团队**: 提供了强大的 AI 助手集成
  - **所有插件开发者**: 让 Neovim 生态如此丰富

## 🔗 相关链接

  - [Neovim 官网](https://neovim.io/)
  - [lazy.nvim 文档](https://github.com/folke/lazy.nvim)
  - [CodeCompanion.nvim](https://github.com/olimorris/codecompanion.nvim)
  - [MCP Hub](https://github.com/ravitemer/mcphub.nvim)
