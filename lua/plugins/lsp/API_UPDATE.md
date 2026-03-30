# LSP API 更新说明

## 问题
Neovim 0.11 弃用了 `require('lspconfig')` 框架，推荐使用新的 `vim.lsp.config` API。

## 错误信息
```
require('lspconfig') "framework" is deprecated, use vim.lsp.config (see :help lspconfig-nvim-0.11) instead.
Feature will be removed in nvim-lspconfig v3.0.0
```

## 修复内容

### 1. 更新 `lsp_config_loader.lua`
- 将 `require("lspconfig")` 改为 `vim.lsp.config`
- 更新相关通知消息

**修改前：**
```lua
local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
if ok_lspconfig and lspconfig[server_name] then
  lspconfig[server_name].setup(config)
  custom_notify("✅ " .. server_name .. " 已通过 lspconfig 加载", vim.log.levels.INFO)
```

**修改后：**
```lua
if vim.lsp.config and vim.lsp.config[server_name] then
  vim.lsp.config[server_name].setup(config)
  custom_notify("✅ " .. server_name .. " 已通过 vim.lsp.config 加载", vim.log.levels.INFO)
```

### 2. 更新 `debug_lsp.lua`
- 将检查 `nvim-lspconfig` 改为检查 `vim.lsp.config`

**修改前：**
```lua
local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
if ok_lspconfig then
  print("✅ nvim-lspconfig 已加载")
```

**修改后：**
```lua
if vim.lsp.config then
  print("✅ vim.lsp.config 已可用")
```

## 新的 API 使用方法

### 1. 检查 API 是否可用
```lua
if vim.lsp.config then
  -- API 可用
end
```

### 2. 设置 LSP 服务器
```lua
-- 方法1: 使用 vim.lsp.config
if vim.lsp.config and vim.lsp.config.lua_ls then
  vim.lsp.config.lua_ls.setup({
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } }
      }
    }
  })
end

-- 方法2: 使用 vim.lsp.start (推荐)
vim.lsp.start({
  name = "lua_ls",
  config = {
    cmd = {"lua-language-server"},
    filetypes = {"lua"},
    settings = {
      Lua = {
        diagnostics = { globals = { "vim" } }
      }
    }
  }
})
```

### 3. 获取服务器配置
```lua
-- 检查特定服务器是否可用
if vim.lsp.config.lua_ls then
  -- lua_ls 配置可用
end

-- 列出所有可用服务器
for server_name, _ in pairs(vim.lsp.config) do
  print("可用服务器: " .. server_name)
end
```

## 兼容性说明

1. **Neovim 0.11+**: 必须使用 `vim.lsp.config`
2. **旧版本**: 可能仍然支持 `require('lspconfig')`，但建议更新
3. **过渡期**: 代码中保留了回退机制，如果 `vim.lsp.config` 不可用，会使用 `vim.lsp.start`

## 验证修复
重启 Neovim 后，警告信息应该不再出现。可以打开一个支持 LSP 的文件（如 `.lua` 文件）来验证 LSP 功能是否正常工作。

## 参考链接
- `:help lspconfig-nvim-0.11`
- Neovim 0.11 发布说明
- nvim-lspconfig 文档