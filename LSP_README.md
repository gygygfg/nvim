# Neovim LSP 配置指南 (Neovim 0.11.6)

## 配置概述

已成功配置完整的LSP（Language Server Protocol）支持，包括：

1. **Mason** - LSP服务器包管理器
2. **mason-lspconfig** - Mason与LSP配置的桥梁
3. **nvim-lspconfig** - Neovim LSP配置
4. **nvim-cmp** - 自动补全引擎
5. **LuaSnip** - 代码片段支持
6. **诊断配置** - 错误提示和警告

## 已配置的LSP服务器

根据您的`servers`目录，已配置以下LSP服务器：

- `ast_grep` - 代码搜索和重构
- `bashls` - Bash语言服务器
- `biome` - JavaScript/TypeScript格式化器和linter
- `clangd` - C/C++语言服务器
- `eslint` - JavaScript/TypeScript代码检查
- `gopls` - Go语言服务器
- `html` - HTML语言服务器
- `lua_ls` - Lua语言服务器（Neovim配置专用）
- `pyright` - Python语言服务器
- `rust_analyzer` - Rust语言服务器
- `taplo` - TOML语言服务器
- `ts_ls` - TypeScript语言服务器
- `vimls` - VimScript语言服务器
- `vtsls` - Vue/TypeScript语言服务器
- `yamlls` - YAML语言服务器

## 使用方法

### 1. 安装LSP服务器

打开Neovim，运行以下命令安装LSP服务器：

```vim
:Mason
```

在Mason界面中，按`i`键安装选中的服务器，或按`I`键安装所有服务器。

### 2. 检查LSP状态

```vim
:LspInfo
```

### 3. 测试配置

```vim
:luafile test_lsp.lua
```

### 4. 常用LSP快捷键

- `K` - 显示悬停文档
- `gd` - 跳转到定义
- `gr` - 查找引用
- `<leader>rn` - 重命名符号
- `<leader>ca` - 代码操作
- `gh` - 显示悬停（备用）
- `g[` - 上一个诊断
- `g]` - 下一个诊断
- `go` - 打开诊断浮窗
- `<leader>q` - 将诊断添加到位置列表

### 5. 自动补全

- `<Tab>` - 选择下一个补全项/展开代码片段
- `<S-Tab>` - 选择上一个补全项
- `<C-.>` - 触发补全
- `<C-,>` - 取消补全
- `<CR>` - 确认选择

## 故障排除

### 1. LSP服务器未启动

检查服务器是否已安装：
```vim
:Mason
```

### 2. 诊断不显示

确保文件类型正确，并且对应的LSP服务器已安装并配置。

### 3. 补全不工作

检查`nvim-cmp`配置，确保已正确加载。

### 4. 更新所有包

```vim
:MasonUpdateAll
```

## 自定义配置

### 添加新的LSP服务器

1. 在`.config/nvim/lua/plugins/lsp/servers/`目录下创建新的Lua文件
2. 文件名为服务器名称，例如：`tsserver.lua`
3. 返回配置表，例如：

```lua
return {
  settings = {
    -- 服务器特定设置
  },
  on_attach = function(client, bufnr)
    -- 自定义附加函数
  end
}
```

### 修改现有配置

直接编辑对应的服务器配置文件即可。

## 注意事项

1. 首次启动时，Mason可能会自动安装配置的LSP服务器
2. 某些LSP服务器需要额外的系统依赖
3. 大型项目可能需要配置工作区设置
4. 定期运行`:MasonUpdateAll`更新所有包

## 支持的文件类型

当前配置支持以下文件类型的LSP：

- Lua (.lua)
- Python (.py)
- JavaScript/TypeScript (.js, .ts, .jsx, .tsx)
- HTML (.html)
- CSS (.css)
- JSON (.json)
- YAML (.yaml, .yml)
- TOML (.toml)
- Rust (.rs)
- Go (.go)
- C/C++ (.c, .cpp, .h)
- Bash (.sh)
- VimScript (.vim)
- Vue (.vue)

## 故障排除

### 常见问题1: "cmd: expected table, got nil" 错误

**问题描述**: 启动Neovim时出现以下错误：
```
/usr/share/nvim/runtime/lua/vim/lsp/rpc.lua:660: cmd: expected table, got nil
```

**原因**: 在Neovim 0.11+版本中，LSP配置需要正确的`cmd`参数。

**解决方案**: 已修复配置，现在使用`mason-lspconfig`自动处理命令路径。

**验证修复**: 
1. 重启Neovim
2. 检查错误是否消失
3. 运行`:LspInfo`查看服务器状态

### 常见问题2: LSP服务器未启动

**检查步骤**:
1. 确认服务器已安装：`:Mason`
2. 检查可执行文件：`ls -la ~/.local/share/nvim/mason/bin/`
3. 查看LSP日志：`:LspLog`

**解决方案**:
1. 通过Mason安装缺失的服务器
2. 确保文件类型正确匹配
3. 检查服务器特定配置

### 常见问题3: 自动补全不工作

**检查步骤**:
1. 确认cmp已加载：`:checkhealth cmp`
2. 检查LSP客户端：`:LspInfo`
3. 验证文件类型：`:set ft?`

**解决方案**:
1. 确保LSP服务器已正确附加到缓冲区
2. 检查`capabilities`配置
3. 验证cmp源配置

## 配置修复历史

### 2026-02-15: 修复LSP命令配置

**问题**: Neovim 0.11+ API需要明确的`cmd`参数

**修复**: 
1. 统一使用`lspconfig` API处理兼容性
2. 通过`mason-lspconfig.setup_handlers()`自动配置
3. 保留自定义服务器配置

**文件**: `lua/plugins/lsp/mason_setup.lua`

## 技术支持

如需进一步帮助：

1. 检查Neovim版本：`:version`
2. 查看完整日志：`:messages`
3. 验证插件状态：`:checkhealth`
4. 检查LSP状态：`:LspInfo`和`:LspLog`