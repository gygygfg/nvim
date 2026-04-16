-- 测试重新加载 LSP 配置
local function test_reload()
  print("=== 测试 LSP 重新加载 ===")
  
  -- 1. 停止所有 LSP 客户端
  local clients = vim.lsp.get_clients()
  print("当前 LSP 客户端数量: " .. #clients)
  for _, client in ipairs(clients) do
    print("  - " .. client.name .. " (ID: " .. client.id .. ")")
  end
  
  -- 2. 重新加载 LSP 配置
  print("\n重新加载 LSP 配置...")
  require("lsp").setup()
  
  -- 3. 等待一会儿，然后检查状态
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
    for name, count in pairs(clients_by_name) do
      print("  - " .. name .. ": " .. count .. " 个实例")
      if count > 1 then
        print("    ⚠️  发现重复!")
      end
    end
    
    print("\n=== 测试完成 ===")
  end, 1000)
end

-- 导出函数
return {
  test_reload = test_reload
}