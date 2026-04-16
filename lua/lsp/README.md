# LSP 配置说明

## 已修复的问题

### 1. LSP 服务器启动问题
- **问题**: `cmd: expected table, got nil` 警告
- **原因**: LSP 配置文件缺少 `cmd` 字段
- **解决方案**: 为所有 LSP 服务器配置文件添加了 `cmd` 字段

### 2. lua_ls 无法识别 vim 变量
- **问题**: lua_ls 配置加载但无法识别 vim 全局变量
- **原因**: 配置中缺少必要的全局变量声明和运行时路径
- **解决方案**: 
  - 添加了更多全局变量到 `diagnostics.globals`
  - 增强了 `workspace.library` 配置
  - 添加了完整的 `runtime.path` 配置

### 3. 重复的 LSP 客户端
- **问题**: 同一个 LSP 服务器有多个实例运行
- **原因**: 多个地方尝试启动同一个服务器
- **解决方案**: 
  - 添加了重复检查
  - 优化了服务器启动逻辑

## 可用的命令

### 状态检查命令
1. `:LspStatus` - 显示当前缓冲区的 LSP 状态
2. `:LspClients` - 显示所有 LSP 客户端的详细信息
3. `:LuaLSStatus` - 专门检查 lua_ls 状态
4. `:LspListServers` - 列出所有可用的 LSP 服务器

### 调试命令
1. `:LspDebug` - 切换 LSP 调试模式
2. `:LspDebugLoad` - 调试 LSP 加载流程
3. `:LspCleanup` - 清理重复的 LSP 客户端

### 管理命令
1. `:LspReload` - 重新加载 LSP 配置
2. `:LspInstallMissing` - 安装缺失的 LSP 服务器
3. `:FormatterInstallMissing` - 安装缺失的格式化工具
4. `:TestLuaLS` - 创建测试缓冲区验证 lua_ls 功能

## 配置文件结构

### LSP 服务器配置
配置文件位于 `~/.config/nvim/lua/lsp/configs/`:
- `lua_ls.lua` - Lua 语言服务器
- `pyright.lua` - Python 语言服务器
- `ts_ls.lua` - TypeScript/JavaScript 语言服务器
- `html.lua` - HTML 语言服务器
- `cssls.lua` - CSS 语言服务器
- `jsonls.lua` - JSON 语言服务器
- `yamlls.lua` - YAML 语言服务器
- `bashls.lua` - Bash 语言服务器
- `clangd.lua` - C/C++ 语言服务器
- `gopls.lua` - Go 语言服务器
- `rust_analyzer.lua` - Rust 语言服务器

### 文件类型映射
在 `init.lua` 中的 `M.filetype_mappings` 定义了文件类型到 LSP 服务器的映射。

### 格式化器配置
在 `init.lua` 中的 `M.formatters_by_ft` 定义了文件类型到格式化工具的映射。

## 按键映射

### 全局 LSP 按键
- `gK` - 显示悬停文档
- `gd` - 跳转到定义
- `<leader>ca` - 代码操作
- `<leader>rn` - 重命名符号
- `<leader>cf` - 格式化文档
- `gr` - 查看引用
- `gi` - 查看实现
- `gt` - 跳转到类型定义
- `<C-k>` - 签名帮助（插入模式）

### 诊断相关
- `g[` - 上一个诊断
- `g]` - 下一个诊断
- `go` - 打开诊断浮动窗口
- `<leader>q` - 设置位置列表

### 格式化
- `<leader>f` - 使用 conform.nvim 格式化

## 自动格式化

### 保存时自动格式化
配置了 `conform.nvim` 在保存时自动格式化，支持：
1. 文件类型特定的格式化器
2. LSP 格式化回退
3. 异步格式化

### 跳过的文件类型
以下文件类型跳过 LSP 检查和格式化：
- `notify` - vim.notify 插件弹出的悬浮文本
- `NvimTree` - 文件管理器
- `TelescopePrompt` - Telescope 提示框
- `packer` - 插件管理器
- `help` - 帮助文档
- `qf` - 快速修复列表
- `terminal` - 终端
- `""` - 空文件类型

## 故障排除

### 常见问题

1. **LSP 服务器未启动**
   - 运行 `:LspInstallMissing` 安装缺失的服务器
   - 运行 `:LspReload` 重新加载配置
   - 检查 `:LspStatus` 查看状态

2. **格式化不工作**
   - 运行 `:FormatterInstallMissing` 安装格式化工具
   - 检查 `:LspStatus` 查看格式化支持
   - 运行 `:TestLuaLS` 测试 lua 格式化

3. **重复的 LSP 客户端**
   - 运行 `:LspCleanup` 清理重复实例
   - 运行 `:LspClients` 查看详细信息

4. **调试模式**
   - 运行 `:LspDebug` 启用调试模式
   - 查看日志输出
   - 运行 `:LspDebugLoad` 调试加载流程

### 日志位置
- LSP 日志: `~/.local/state/nvim/lsp.log`
- 输出日志: `~/.config/nvim/lua/lsp/output.log`

## 性能优化

1. **避免重复启动**: 服务器已运行时只附加不启动
2. **延迟加载**: 使用 `vim.defer_fn` 延迟加载部分配置
3. **按需启动**: 只在需要时启动 LSP 服务器
4. **缓存配置**: 使用 `setmetatable` 缓存服务器配置

## 扩展性

### 添加新的 LSP 服务器
1. 在 `configs/` 目录创建配置文件
2. 在 `M.filetype_mappings` 中添加文件类型映射
3. 在 `M.lsp_to_mason` 中添加 Mason 包名映射
4. 在 `M.formatters_by_ft` 中添加格式化器配置（如果需要）

### 添加新的格式化器
1. 在 `M.formatters_by_ft` 中添加文件类型映射
2. 在 `M.formatter_to_mason` 中添加 Mason 包名映射
3. 在 `setup_conform` 函数中添加格式化器选项

## 版本兼容性

- **Neovim 0.12+**: 使用新的 `vim.lsp` API
- **Mason**: 用于管理 LSP 服务器和格式化工具
- **conform.nvim**: 用于代码格式化
- **mason-lspconfig**: 自动配置 LSP 服务器

## 最后更新
2026年4月16日 - 修复了 LSP 服务器启动问题和 lua_ls 配置问题