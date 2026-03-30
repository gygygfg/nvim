-- 测试语法修复
print("=== 测试 LSP 配置加载器语法 ===")

-- 尝试加载模块
local ok, loader = pcall(require, "plugins.lsp.mason.lsp_config_loader")
if ok then
  print("✅ lsp_config_loader 模块加载成功")
  
  -- 测试扫描配置
  local configs = loader.scan_lsp_configs()
  print("✅ 扫描到 " .. #configs .. " 个 LSP 配置")
  
  -- 测试加载单个配置
  if #configs > 0 then
    local test_config = configs[1]
    local config = loader.load_lsp_config(test_config)
    if config then
      print("✅ " .. test_config .. " 配置加载成功")
      print("  cmd:", vim.inspect(config.cmd))
    else
      print("❌ " .. test_config .. " 配置加载失败")
    end
  end
  
  -- 测试 setup_all_lsp_servers 函数（不实际启动）
  print("\n测试 setup_all_lsp_servers 函数结构...")
  local loaded = loader.setup_all_lsp_servers()
  print("✅ setup_all_lsp_servers 执行成功")
  print("  返回 loaded_servers 表:", type(loaded) == "table")
  
else
  print("❌ lsp_config_loader 模块加载失败:")
  print(loader)
end

print("\n=== 语法测试完成 ===")
print("\n建议下一步:")
print("1. 重新启动 Neovim")
print("2. 检查是否还有语法错误")
print("3. 测试具体的 LSP 服务器")