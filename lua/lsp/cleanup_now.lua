-- 立即清理重复的 LSP 客户端
print("=== 立即清理重复 LSP 客户端 ===")

-- 获取 LSP 模块
local lsp_ok, lsp_module = pcall(require, "lsp")
if not lsp_ok then
  print("错误: 无法加载 LSP 模块")
  return
end

-- 检查当前状态
local all_clients = vim.lsp.get_clients()
print("清理前 LSP 客户端数量: " .. #all_clients)

-- 显示当前客户端
local clients_by_name = {}
for _, client in ipairs(all_clients) do
  if not clients_by_name[client.name] then
    clients_by_name[client.name] = 0
  end
  clients_by_name[client.name] = clients_by_name[client.name] + 1
  print("  - " .. client.name .. " (ID: " .. client.id .. ")")
end

-- 检查重复
print("\n重复检查:")
for name, count in pairs(clients_by_name) do
  if count > 1 then
    print("  ⚠️  " .. name .. ": " .. count .. " 个实例")
  end
end

-- 运行清理
print("\n运行清理...")
lsp_module.cleanup_duplicate_clients()

-- 检查清理后的状态
vim.defer_fn(function()
  print("\n清理后状态:")
  local new_clients = vim.lsp.get_clients()
  print("LSP 客户端数量: " .. #new_clients)
  
  local new_clients_by_name = {}
  for _, client in ipairs(new_clients) do
    if not new_clients_by_name[client.name] then
      new_clients_by_name[client.name] = 0
    end
    new_clients_by_name[client.name] = new_clients_by_name[client.name] + 1
  end
  
  for name, count in pairs(new_clients_by_name) do
    if count > 1 then
      print("  ⚠️  " .. name .. ": " .. count .. " 个实例 (仍然重复!)")
    else
      print("  ✓ " .. name .. ": " .. count .. " 个实例")
    end
  end
  
  print("\n=== 清理完成 ===")
end, 100)