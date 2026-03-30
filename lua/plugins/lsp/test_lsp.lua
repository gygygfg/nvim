-- 测试 LSP 配置
local function test_lsp_config()
  print("测试 LSP 配置...")
  
  -- 测试加载单个配置
  local loader = require("plugins.lsp.mason.lsp_config_loader")
  
  -- 测试 bashls 配置
  local bashls_config = loader.load_lsp_config("bashls")
  if bashls_config then
    print("✅ bashls 配置加载成功")
    print("  cmd:", vim.inspect(bashls_config.cmd))
    print("  filetypes:", vim.inspect(bashls_config.filetypes))
  else
    print("❌ bashls 配置加载失败")
  end
  
  -- 测试 lua_ls 配置
  local lua_ls_config = loader.load_lsp_config("lua_ls")
  if lua_ls_config then
    print("✅ lua_ls 配置加载成功")
    print("  cmd:", vim.inspect(lua_ls_config.cmd))
    print("  filetypes:", vim.inspect(lua_ls_config.filetypes))
  else
    print("❌ lua_ls 配置加载失败")
  end
  
  -- 测试扫描配置
  local configs = loader.scan_lsp_configs()
  print("📋 扫描到的 LSP 配置:", #configs)
  for i, config in ipairs(configs) do
    print("  " .. i .. ". " .. config)
  end
end

-- 运行测试
test_lsp_config()