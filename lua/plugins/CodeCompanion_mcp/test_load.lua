-- 测试模块加载

local function test_load()
  print("测试模块加载...")
  
  -- 测试加载 minimal_fix 模块
  local ok, minimal_fix = pcall(require, "extensions.minimal_fix")
  if ok then
    print("✓ minimal_fix 模块加载成功")
  else
    print("✗ minimal_fix 模块加载失败: " .. tostring(minimal_fix))
  end
  
  -- 测试加载 config.config 模块
  local ok2, config = pcall(require, "config.config")
  if ok2 then
    print("✓ config.config 模块加载成功")
  else
    print("✗ config.config 模块加载失败: " .. tostring(config))
  end
  
  -- 显示当前包路径
  print("\n当前包路径:")
  for path in string.gmatch(package.path, "[^;]+") do
    if string.find(path, "CodeCompanion_mcp") then
      print("  " .. path)
    end
  end
end

return {
  test_load = test_load
}