# LSPConfig 迁移问题

## 问题描述
用户在使用 Neovim 0.11.6 时遇到 `require('lspconfig')` 框架已被弃用的警告。根据错误信息，需要将代码从 `require('lspconfig')` 迁移到新的 `vim.lsp.config` API。

## 错误信息
```
require('lspconfig') "framework" is deprecated, use vim.lsp.config (see :help lspconfig-nvim-0.11) instead.
Feature will be removed in nvim-lspconfig v3.0.0
```

## 相关文件
1. `/root/.config/nvim/lua/plugins/lsp/mason/lsp_config_loader.lua:128`
   - 使用 `require("lspconfig")[server_name].setup(config)`
2. `/root/.config/nvim/lua/plugins/lsp/mason/init.lua:87`
   - 调用 `lsp_loader.setup_all_lsp_servers()`

## 需要修改的代码

### 1. `lsp_config_loader.lua` 的第 128 行：
```lua
require("lspconfig")[server_name].setup(config)
```

需要改为新的 API：
```lua
vim.lsp.config[server_name].setup(config)
```

### 2. `mason_setup.lua` 的第 100 行：
```lua
local lspconfig = require("lspconfig")
```

需要改为：
```lua
local lspconfig = vim.lsp.config
```

## 已完成的修改

1. ✅ `lsp_config_loader.lua` - 已修复为使用正确的 `vim.lsp.start({ name = server_name, config = config })` API
   - 之前错误地使用了 `vim.lsp.config.add({ name = server_name, config = config })`，这会导致 "attempt to call field 'add' (a nil value)" 错误
   - 在 Neovim 0.11.6 中，正确的 API 是 `vim.lsp.start()`
2. ✅ `minimal_setup.lua` - 已修复为使用正确的 `vim.lsp.start({ name = server_name, config = config })` API
   - 之前错误地使用了 `vim.lsp.config.add({ name = server_name, config = config })`，这会导致同样的错误
3. ✅ `mason_setup.lua` - 已修复为使用正确的 `vim.lsp.start({ name = server_name, config = config })` API
   - 之前错误地使用了 `vim.lsp.config.add({ name = server_name, config = config })`，这会导致同样的错误

## 注意事项
- `minimal_setup.lua` 已经正确使用了新的 `vim.lsp.config.add()` API
- LSP 配置文件（如 `lua_ls.lua`, `pyright.lua` 等）不需要修改，它们只是返回配置表
- 其他 LSP 配置文件已被简化，移除了对 `lspconfig.util` 的依赖

## 修复的问题

### 第一阶段问题
- **问题**: 多个 LSP 服务器加载失败，错误信息为 "attempt to call field 'setup' (a nil value)"
- **原因**: 使用了错误的 API `vim.lsp.config[server_name].setup(config)`，而正确的 API 是 `vim.lsp.config.add({ name = server_name, config = config })`
- **解决方案**: 更新 `lsp_config_loader.lua` 第 128 行附近的代码，使用正确的 API

### 第二阶段问题
- **问题**: 多个 LSP 服务器加载失败，错误信息为 "attempt to call field 'add' (a nil value)"
- **原因**: 使用了错误的 API `vim.lsp.config.add({ name = server_name, config = config })`，在 Neovim 0.11.6 中这个 API 不存在
- **解决方案**: 更新为使用正确的 `vim.lsp.start({ name = server_name, config = config })` API
- **影响文件**: 
  - `lsp_config_loader.lua` 第 128 行附近
  - `minimal_setup.lua` 第 90 行附近
  - `mason_setup.lua` 第 110 行附近

## 测试建议
1. 重启 Neovim 以应用更改
2. 打开一个支持的文件（如 `.lua` 文件）来测试 LSP 是否正常工作
3. 检查是否还有弃用警告或加载失败的错误出现