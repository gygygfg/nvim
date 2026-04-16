-- 重新加载 LSP 配置并修复重复问题
print("=== 重新加载 LSP 配置 ===")

-- 1. 先停止所有 LSP 客户端
local clients = vim.lsp.get_clients()
print("停止 " .. #clients .. " 个 LSP 客户端...")
for _, client in ipairs(clients) do
  client.terminate()
end

-- 2. 清除所有缓冲区的 lsp_started 标记
for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
  vim.b[bufnr].lsp_started = nil
end

-- 3. 重新加载 LSP 模块
print("重新加载 LSP 模块...")
package.loaded["lsp"] = nil
local lsp_ok, lsp_module = pcall(require, "lsp")

if not lsp_ok then
  print("错误: 无法重新加载 LSP 模块: " .. tostring(lsp_module))
  return
end

-- 4. 重新设置 LSP
print("重新设置 LSP...")
lsp_module.setup()

-- 5. 等待设置完成，然后检查状态
vim.defer_fn(function()
  print("\n重新加载后的状态:")
  
  local new_clients = vim.lsp.get_clients()
  print("LSP 客户端数量: " .. #new_clients)
  
  -- 按名称分组
  local clients_by_name = {}
  for _, client in ipairs(new_clients) do
    if not clients_by_name[client.name] then
      clients_by_name[client.name] = 0
    end
    clients_by_name[client.name] = clients_by_name[client.name] + 1
  end
  
  -- 检查重复
  local has_duplicates = false
  for name, count in pairs(clients_by_name) do
    if count > 1 then
      print("  ⚠️  " .. name .. ": " .. count .. " 个实例 (重复!)")
      has_duplicates = true
    else
      print("  ✓ " .. name .. ": " .. count .. " 个实例")
    end
  end
  
  if has_duplicates then
    print("\n仍然存在重复的 LSP 客户端")
    print("运行清理函数...")
    lsp_module.cleanup_duplicate_clients()
  else
    print("\n✓ 没有发现重复的 LSP 客户端")
  end
  
  -- 检查当前缓冲区的 LSP 状态
  local current_buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype
  print("\n当前缓冲区: " .. current_buf)
  print("文件类型: " .. (ft or "无"))
  print("lsp_started 标记: " .. tostring(vim.b[current_buf].lsp_started))
  
  local buf_clients = vim.lsp.get_clients({ bufnr = current_buf })
  print("附加到当前缓冲区的 LSP 客户端: " .. #buf_clients .. " 个")
  for _, client in ipairs(buf_clients) do
    print("  - " .. client.name .. " (ID: " .. client.id .. ")")
  end
  
  print("\n=== 重新加载完成 ===")
  vim.notify("LSP 配置已重新加载", vim.log.levels.INFO)
end, 2000)