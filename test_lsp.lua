-- 测试 LSP 配置
print("测试 LSP 配置...")

-- 检查 config.lsp 模块是否已加载
local ok, config_lsp = pcall(require, 'config.lsp')
if not ok then
  print("❌ config.lsp 模块未加载:", config_lsp)
  return
end

print("✅ config.lsp 模块已加载")

-- 检查服务器列表
local servers = config_lsp.get_servers()
print("📋 服务器列表:", #servers)
for i, server in ipairs(servers) do
  print("  " .. i .. ". " .. server)
end

-- 检查 LSP 命令是否可用
local commands = {
  "LspFind",
  "LspFindForFiletype", 
  "LspList",
  "LspReload",
  "LspInstallAll",
  "MasonSearch",
  "MasonToolchain"
}

print("🔧 检查命令...")
for _, cmd in ipairs(commands) do
  local cmd_info = vim.api.nvim_get_commands({})
  if cmd_info[cmd] then
    print("  ✅ " .. cmd .. " - " .. (cmd_info[cmd].desc or "无描述"))
  else
    print("  ❌ " .. cmd .. " 未找到")
  end
end

print("🎉 测试完成")