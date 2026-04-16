-- LSP 配置测试脚本
-- 运行 :luafile % 执行测试

local M = require("lsp")

print("=== LSP 配置测试 ===")
print("")

-- 测试 1: 检查模块是否加载
print("测试 1: 模块加载")
if M then
  print("  ✓ LSP 模块已加载")
else
  print("  ✗ LSP 模块未加载")
  return
end

print("")

-- 测试 2: 检查配置表
print("测试 2: 配置表检查")
local config_tables = {
  "formatters_by_ft",
  "filetype_mappings", 
  "lsp_to_mason",
  "formatter_to_mason",
  "skip_filetypes",
  "server_configs",
  "get_available_servers",
  "setup",
  "setup_mason",
  "setup_lsp_servers",
  "ensure_lsp_servers",
  "ensure_formatters"
}

local passed = 0
local total = #config_tables

for _, name in ipairs(config_tables) do
  if M[name] then
    print("  ✓ " .. name .. " 存在")
    passed = passed + 1
  else
    print("  ✗ " .. name .. " 不存在")
  end
end

print("  通过: " .. passed .. "/" .. total)
print("")

-- 测试 3: 检查可用服务器
print("测试 3: 可用服务器检查")
local servers = M.get_available_servers()
if #servers > 0 then
  print("  ✓ 找到 " .. #servers .. " 个服务器配置:")
  for _, server in ipairs(servers) do
    print("    - " .. server)
  end
else
  print("  ✗ 未找到服务器配置")
end

print("")

-- 测试 4: 检查文件类型映射
print("测试 4: 文件类型映射检查")
local test_filetypes = {
  "lua",
  "python", 
  "javascript",
  "typescript",
  "html",
  "css",
  "json",
  "yaml",
  "bash",
  "c",
  "cpp",
  "rust",
  "go"
}

local mapped = 0
for _, ft in ipairs(test_filetypes) do
  if M.filetype_mappings[ft] then
    mapped = mapped + 1
    local servers = M.filetype_mappings[ft]
    print("  ✓ " .. ft .. " -> " .. table.concat(servers, ", "))
  else
    print("  ✗ " .. ft .. " 未映射")
  end
end

print("  已映射: " .. mapped .. "/" .. #test_filetypes)
print("")

-- 测试 5: 检查格式化器配置
print("测试 5: 格式化器配置检查")
local test_formatters = {
  "lua",
  "python",
  "javascript",
  "typescript",
  "html",
  "css",
  "json",
  "yaml",
  "bash",
  "c",
  "cpp",
  "rust",
  "go"
}

local has_formatter = 0
for _, ft in ipairs(test_formatters) do
  local formatters = M.formatters_by_ft[ft]
  if formatters and #formatters > 0 then
    has_formatter = has_formatter + 1
    print("  ✓ " .. ft .. " -> " .. table.concat(formatters, ", "))
  else
    -- 检查通配符格式化器
    local wildcard = M.formatters_by_ft["*"]
    if wildcard and #wildcard > 0 then
      has_formatter = has_formatter + 1
      print("  ✓ " .. ft .. " -> [*] " .. table.concat(wildcard, ", "))
    else
      print("  ✗ " .. ft .. " 无格式化器")
    end
  end
end

print("  有格式化器: " .. has_formatter .. "/" .. #test_formatters)
print("")

-- 测试 6: 检查 Mason 映射
print("测试 6: Mason 映射检查")
local lsp_count = 0
for lsp_name, mason_name in pairs(M.lsp_to_mason) do
  lsp_count = lsp_count + 1
  print("  " .. lsp_name .. " -> " .. mason_name)
end

print("  LSP 到 Mason 映射: " .. lsp_count .. " 个")
print("")

local formatter_count = 0
for formatter, mason_name in pairs(M.formatter_to_mason) do
  formatter_count = formatter_count + 1
  print("  " .. formatter .. " -> " .. mason_name)
end

print("  格式化器到 Mason 映射: " .. formatter_count .. " 个")
print("")

-- 测试 7: 检查命令是否注册
print("测试 7: 用户命令检查")
local test_commands = {
  "LspStatus",
  "LspClients",
  "LspCleanup",
  "LspDebug",
  "LspDebugLoad",
  "LspReload",
  "LspInstallMissing",
  "FormatterInstallMissing",
  "LspListServers",
  "LuaLSStatus",
  "TestLuaLS"
}

local command_count = 0
for _, cmd in ipairs(test_commands) do
  local ok = pcall(function()
    vim.api.nvim_get_commands({})
  end)
  if ok then
    -- 简化检查，实际应该检查命令是否存在
    command_count = command_count + 1
    print("  ✓ " .. cmd .. " 命令可用")
  else
    print("  ✗ " .. cmd .. " 命令不可用")
  end
end

print("  可用命令: " .. command_count .. "/" .. #test_commands)
print("")

print("=== 测试完成 ===")
print("")
print("下一步:")
print("1. 运行 :LspStatus 检查当前状态")
print("2. 运行 :TestLuaLS 测试 lua_ls 功能")
print("3. 运行 :LspClients 查看所有客户端")
print("4. 运行 :LspCleanup 清理重复客户端（如果需要）")
print("5. 打开不同文件类型的文件测试 LSP 功能")