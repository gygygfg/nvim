-- 测试 LSP 修复
-- 运行: :lua require('plugins.lsp.test_fix').test()

local M = {}

function M.test()
  print("🧪 测试 LSP 修复...")
  
  -- 测试 rust-analyzer 配置
  local ok_ra, config_ra = pcall(require, "plugins/lsp/mason/lsp/rust_analyzer")
  if ok_ra and type(config_ra) == "table" then
    print("✅ rust-analyzer 配置加载成功")
    print("  cmd:", vim.inspect(config_ra.cmd))
    print("  root_dir:", type(config_ra.root_dir))
  else
    print("❌ rust-analyzer 配置加载失败:", config_ra)
  end
  
  -- 测试 vtsls 配置
  local ok_vt, config_vt = pcall(require, "plugins/lsp/mason/lsp/vtsls")
  if ok_vt and type(config_vt) == "table" then
    print("✅ vtsls 配置加载成功")
    print("  cmd:", vim.inspect(config_vt.cmd))
    if config_vt.cmd and #config_vt.cmd > 1 then
      print("  包含 --stdio:", config_vt.cmd[2] == "--stdio")
    end
  else
    print("❌ vtsls 配置加载失败:", config_vt)
  end
  
  -- 测试 eslint 配置
  local ok_es, config_es = pcall(require, "plugins/lsp/mason/lsp/eslint")
  if ok_es and type(config_es) == "table" then
    print("✅ eslint 配置加载成功")
    print("  cmd:", vim.inspect(config_es.cmd))
    print("  settings:", type(config_es.settings))
  else
    print("❌ eslint 配置加载失败:", config_es)
  end
  
  -- 测试 LSP 配置加载器
  local ok_loader, loader = pcall(require, "plugins/lsp/mason/lsp_config_loader")
  if ok_loader then
    print("✅ LSP 配置加载器加载成功")
    local configs = loader.scan_lsp_configs()
    print("  找到配置:", #configs, "个")
    for _, name in ipairs(configs) do
      print("    - " .. name)
    end
  else
    print("❌ LSP 配置加载器加载失败:", loader)
  end
  
  -- 测试当前 LSP 状态
  print("\n📊 当前 LSP 状态:")
  local clients = vim.lsp.get_active_clients()
  if #clients > 0 then
    for _, client in ipairs(clients) do
      print("  " .. client.name .. " (" .. client.id .. ")")
    end
  else
    print("  没有活动的 LSP 客户端")
  end
  
  print("\n💡 建议:")
  print("1. 运行 :LspRestart 重启 LSP")
  print("2. 打开相应文件类型的文件")
  print("3. 检查 :LspInfo")
  print("4. 查看日志: /root/.local/state/nvim/lsp.log")
end

return M