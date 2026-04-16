-- 运行修复脚本
print("加载修复模块...")

-- 加载状态检查
local status_ok, _ = pcall(require, "lsp.check_status")
if not status_ok then
  print("无法加载状态检查模块")
end

-- 加载修复模块
local fix_ok, fix_module = pcall(require, "lsp.fix_duplicate")
if fix_ok then
  print("运行修复...")
  fix_module.fix()
else
  print("无法加载修复模块: " .. tostring(fix_module))
  
  -- 尝试直接修复
  print("尝试直接修复...")
  
  -- 获取所有客户端
  local all_clients = vim.lsp.get_clients()
  print("当前客户端数量: " .. #all_clients)
  
  -- 按名称分组
  local clients_by_name = {}
  for _, client in ipairs(all_clients) do
    if not clients_by_name[client.name] then
      clients_by_name[client.name] = {}
    end
    table.insert(clients_by_name[client.name], client)
  end
  
  -- 清理重复
  local removed = 0
  for name, client_list in pairs(clients_by_name) do
    if #client_list > 1 then
      print("发现重复: " .. name .. " (" .. #client_list .. " 个实例)")
      
      -- 保留第一个，停止其他的
      for i = 2, #client_list do
        local client = client_list[i]
        print("  停止实例 ID: " .. client.id)
        client.terminate()
        removed = removed + 1
      end
    end
  end
  
  if removed > 0 then
    print("已停止 " .. removed .. " 个重复的 LSP 客户端")
    vim.notify("已清理 " .. removed .. " 个重复的 LSP 客户端", vim.log.levels.INFO)
  else
    print("未发现重复的 LSP 客户端")
  end
end

print("修复完成")