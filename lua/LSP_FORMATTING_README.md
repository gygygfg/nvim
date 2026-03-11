# LSP 格式化功能配置说明

## 已添加的功能

### 1. 保存时自动格式化（增强版）
- **位置**: `local_conf.lua`
- **功能**: 在保存文件时自动格式化代码
- **优先级**: 
  1. 优先使用LSP格式化（如果可用）
  2. 如果LSP不可用，使用 `gg=G` 格式化
  3. 对于缩进敏感的文件类型（yaml, python, dockerfile等），跳过 `gg=G` 格式化

### 2. 手动LSP格式化快捷键
- **位置**: `keymaps.lua` 中的 `M.mason()` 函数
- **快捷键**: `<leader>lf`
- **功能**: 手动触发LSP格式化当前缓冲区
- **描述**: "使用LSP格式化当前缓冲区"

## 支持的LSP服务器

根据您的配置，以下LSP服务器支持格式化功能：

### 已配置的服务器：
1. **pyright** - Python语言服务器（支持格式化）
2. **vtsls** - TypeScript/JavaScript语言服务器（支持格式化）
3. **ts_ls** - TypeScript语言服务器（支持格式化）
4. **biome** - JavaScript/TypeScript格式化工具（支持格式化）
5. **eslint** - JavaScript代码检查工具（可能支持格式化）
6. **gopls** - Go语言服务器（支持格式化）
7. **html** - HTML语言服务器（支持格式化）
8. **yamlls** - YAML语言服务器（支持格式化）
9. **taplo** - TOML语言服务器（支持格式化）

## 如何使用

### 自动格式化
1. 打开任何支持LSP格式化的文件（如 `.py`, `.js`, `.ts`, `.lua` 等）
2. 保存文件（`:w` 或 `Ctrl+s`）
3. 系统会自动使用LSP格式化代码（如果可用）

### 手动格式化
1. 在任何打开的文件中
2. 按下 `<leader>lf` 快捷键
3. 系统会立即使用LSP格式化当前缓冲区

## 验证LSP格式化是否工作

### 方法1：检查LSP客户端
```lua
-- 在Neovim中执行以下命令
:lua print(vim.inspect(vim.lsp.get_clients({bufnr=0})))
```

### 方法2：测试格式化支持
```lua
-- 在Neovim中执行以下命令
:lua 
local clients = vim.lsp.get_clients({bufnr=0})
for _, client in ipairs(clients) do
  if client.supports_method("textDocument/formatting") then
    print(client.name .. " 支持格式化")
  end
end
```

## 故障排除

### 问题1：LSP格式化不工作
**可能原因**: LSP服务器未正确安装或配置
**解决方案**:
1. 检查Mason是否已安装LSP服务器：
   ```
   :Mason
   ```
2. 确保服务器已安装并启用

### 问题2：格式化快捷键无效
**可能原因**: 键位映射冲突
**解决方案**:
1. 检查当前键位映射：
   ```
   :nmap <leader>lf
   ```
2. 如果冲突，可以修改 `keymaps.lua` 中的快捷键

### 问题3：保存时没有格式化
**可能原因**: 没有可用的LSP格式化功能
**解决方案**:
1. 检查当前文件类型是否有对应的LSP服务器
2. 确保LSP服务器支持格式化功能
3. 系统会自动回退到 `gg=G` 格式化

## 自定义配置

### 修改格式化选项
可以在 `local_conf.lua` 中修改 `formatWithLSP` 函数的参数：

```lua
vim.lsp.buf.format({
  async = false,  -- 同步格式化（保存前完成）
  timeout_ms = 5000,  -- 超时时间（毫秒）
  filter = function(client)
    -- 自定义过滤逻辑
    return client.supports_method("textDocument/formatting")
  end
})
```

### 添加新的文件类型支持
在 `local_conf.lua` 的 `sensitive_filetypes` 数组中添加或删除文件类型：

```lua
local sensitive_filetypes = { 
  "yaml", "python", "yml", "py", "dockerfile",
  -- 添加或删除文件类型
  "json", "toml"
}
```

## 性能优化建议

1. **异步格式化**: 对于大型文件，可以考虑使用异步格式化（`async = true`）
2. **超时设置**: 设置合理的超时时间，避免格式化操作卡住
3. **选择性格式化**: 可以为特定文件类型禁用自动格式化

## 注意事项

1. **缩进敏感文件**: YAML、Python等文件对缩进敏感，使用 `gg=G` 格式化可能导致问题
2. **LSP优先级**: 如果有多个LSP客户端支持格式化，系统会使用第一个找到的
3. **回退机制**: 当LSP格式化不可用时，系统会自动使用 `gg=G` 格式化

## 更新日志

- **2026-03-11**: 初始版本，添加LSP格式化功能
- **功能**: 保存时自动格式化 + 手动格式化快捷键
- **兼容性**: 向后兼容现有的 `gg=G` 格式化功能