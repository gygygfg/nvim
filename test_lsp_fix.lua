-- 测试 LSP 修复脚本
local function test_lsp_fix()
  print("=== LSP 修复测试 ===")
  
  -- 1. 测试 vtsls 配置
  local vtsls_config = require("plugins.lsp.mason.lsp.vtsls")
  print("1. vtsls 配置检查:")
  print("  cmd:", vim.inspect(vtsls_config.cmd))
  print("  是否包含 --stdio:", vim.inspect(vim.tbl_contains(vtsls_config.cmd, "--stdio")))
  
  -- 2. 测试 rust_analyzer 配置
  local rust_config = require("plugins.lsp.mason.lsp.rust_analyzer")
  print("\n2. rust_analyzer 配置检查:")
  print("  单文件支持:", rust_config.single_file_support)
  print("  设置:", vim.inspect(rust_config.settings))
  
  -- 3. 测试 lua_ls 配置
  local lua_config = require("plugins.lsp.mason.lsp.lua_ls")
  print("\n3. lua_ls 配置检查:")
  print("  工作区设置:", vim.inspect(lua_config.settings.Lua.workspace))
  
  -- 4. 测试配置加载器
  local loader = require("plugins.lsp.mason.lsp_config_loader")
  local configs = loader.scan_lsp_configs()
  print("\n4. 可用的 LSP 配置:")
  for i, config in ipairs(configs) do
    print("  " .. i .. ". " .. config)
  end
  
  print("\n=== 测试完成 ===")
end

-- 运行测试
test_lsp_fix()

-- 提示用户下一步
print("\n建议下一步:")
print("1. 重新启动 Neovim")
print("2. 打开一个 TypeScript 文件测试 vtsls")
print("3. 打开一个 Rust 文件测试 rust_analyzer")
print("4. 打开一个 Lua 文件测试 lua_ls")