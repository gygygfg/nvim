-- LSP 配置加载诊断脚本
print("=== LSP 配置加载诊断 ===")

-- 启用调试模式
vim.g.lsp_debug = true

-- 1. 检查基础环境
print("\n1. 基础环境检查:")
print("   Neovim 版本:", vim.version())
print("   当前工作目录:", vim.fn.getcwd())
print("   配置文件目录:", vim.fn.expand("~/.config/nvim"))

-- 2. 检查 package.path
print("\n2. package.path 分析:")
local paths = {}
for path in package.path:gmatch("[^;]+") do
  table.insert(paths, path)
end

print("   总路径数:", #paths)
print("   前10个路径:")
for i = 1, math.min(10, #paths) do
  local path = paths[i]
  local has_lua = path:match("lua") and "✓" or "✗"
  print(string.format("    [%02d] %s %s", i, has_lua, path))
end

-- 3. 测试 require "lsp"
print("\n3. 测试 require 'lsp':")
-- 清除缓存
package.loaded["lsp"] = nil

local ok, lsp_module = pcall(require, "lsp")
if ok then
  print("   ✓ require 'lsp' 成功")
  print("   模块类型:", type(lsp_module))
  
  -- 检查关键函数
  local functions_to_check = {
    "setup",
    "setup_mason", 
    "server_configs",
    "start_server_with_config",
    "load_server_config"
  }
  
  print("   关键函数检查:")
  for _, func_name in ipairs(functions_to_check) do
    local has_func = type(lsp_module[func_name]) == "function" or 
                     (func_name == "server_configs" and type(lsp_module[func_name]) == "table")
    print(string.format("     %-25s %s", func_name, has_func and "✓" or "✗"))
  end
else
  print("   ✗ require 'lsp' 失败:", lsp_module)
end

-- 4. 测试配置文件加载
print("\n4. 配置文件加载测试:")
local test_configs = {
  "lua_ls",
  "pyright", 
  "ts_ls"
}

for _, server_name in ipairs(test_configs) do
  print("\n   测试服务器: " .. server_name)
  
  -- 测试1: 直接 loadfile
  local config_path = vim.fn.expand("~/.config/nvim/lua/lsp/configs/" .. server_name .. ".lua")
  local file_exists = vim.fn.filereadable(config_path) == 1
  print("     配置文件路径:", config_path)
  print("     文件存在:", file_exists and "✓" or "✗")
  
  if file_exists then
    local chunk, err = loadfile(config_path)
    if chunk then
      print("     loadfile: ✓ 成功")
      local config = chunk()
      print("     配置类型:", type(config))
      if type(config) == "table" then
        print("     name:", config.name or "未设置")
      end
    else
      print("     loadfile: ✗ 失败:", err)
    end
  end
  
  -- 测试2: 通过 M.server_configs
  if lsp_module and lsp_module.server_configs then
    local config = lsp_module.server_configs[server_name]
    if next(config) ~= nil then
      print("     M.server_configs: ✓ 成功")
      print("     配置 name:", config.name or "未设置")
    else
      print("     M.server_configs: ✗ 失败 (空配置)")
    end
  end
end

-- 5. 检查 LSP 服务器状态
print("\n5. 当前 LSP 服务器状态:")
local all_clients = vim.lsp.get_clients()
print("   总客户端数:", #all_clients)

if #all_clients > 0 then
  print("   客户端列表:")
  for _, client in ipairs(all_clients) do
    print(string.format("     %-20s (ID: %d)", client.name, client.id))
    
    -- 检查配置
    if client.config and client.config.settings then
      print("       配置已加载: ✓")
    else
      print("       配置已加载: ✗")
    end
  end
end

-- 6. 测试启动 lua_ls
print("\n6. 测试启动 lua_ls:")
if lsp_module and lsp_module.start_server_with_config then
  print("   尝试启动 lua_ls...")
  local success = lsp_module.start_server_with_config("lua_ls")
  print("   启动结果:", success and "✓ 成功" or "✗ 失败")
  
  -- 检查是否启动
  vim.defer_fn(function()
    local lua_clients = vim.lsp.get_clients({ name = "lua_ls" })
    print("   lua_ls 客户端数:", #lua_clients)
    
    if #lua_clients > 0 then
      local client = lua_clients[1]
      print("   客户端配置:")
      print("     name:", client.name)
      if client.config and client.config.settings then
        print("     settings: ✓ 存在")
        if client.config.settings.Lua then
          print("     Lua 设置: ✓ 存在")
        end
      end
    end
  end, 1000)
else
  print("   ✗ 无法启动: start_server_with_config 函数不存在")
end

print("\n=== 诊断完成 ===")
print("\n建议:")
print("1. 运行 :LspDebug 启用调试模式")
print("2. 运行 :LspStatus 查看当前状态")
print("3. 运行 :LspReload 重新加载配置")
print("4. 检查 ~/.config/nvim/init.lua 中的 require(\"lsp\").setup() 是否被调用")