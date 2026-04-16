-- 测试 require 路径问题
print("=== 测试 require 路径 ===")

-- 1. 检查当前 package.path
print("1. package.path:")
local lua_paths = {}
for path in package.path:gmatch("[^;]+") do
  if path:match("lua") then
    table.insert(lua_paths, path)
  end
end

for i, path in ipairs(lua_paths) do
  print(string.format("   [%02d] %s", i, path))
end

-- 2. 测试 require "lsp"
print("\n2. 测试 require 'lsp':")
local ok, lsp_module = pcall(require, "lsp")
if ok then
  print("   ✓ require 'lsp' 成功")
  print("   模块类型:", type(lsp_module))
  
  -- 检查是否有 setup 函数
  if type(lsp_module.setup) == "function" then
    print("   ✓ lsp.setup 函数存在")
  else
    print("   ✗ lsp.setup 函数不存在")
  end
else
  print("   ✗ require 'lsp' 失败:", lsp_module)
end

-- 3. 测试 require "lsp.configs.lua_ls"
print("\n3. 测试 require 'lsp.configs.lua_ls':")
local ok2, lua_config = pcall(require, "lsp.configs.lua_ls")
if ok2 then
  print("   ✓ require 'lsp.configs.lua_ls' 成功")
  print("   配置类型:", type(lua_config))
  print("   name:", lua_config.name)
else
  print("   ✗ require 'lsp.configs.lua_ls' 失败:", lua_config)
end

-- 4. 检查文件是否存在
print("\n4. 检查文件是否存在:")
local lsp_init_path = vim.fn.expand("~/.config/nvim/lua/lsp/init.lua")
local lua_ls_config_path = vim.fn.expand("~/.config/nvim/lua/lsp/configs/lua_ls.lua")

print("   lsp/init.lua:", lsp_init_path)
print("     文件存在:", vim.fn.filereadable(lsp_init_path) == 1)
print("   lsp/configs/lua_ls.lua:", lua_ls_config_path)
print("     文件存在:", vim.fn.filereadable(lua_ls_config_path) == 1)

-- 5. 测试从不同目录 require
print("\n5. 测试从不同目录 require:")

-- 保存原始目录
local original_dir = vim.fn.getcwd()

-- 测试1: 在 ~/.config/nvim 目录
vim.cmd("cd " .. vim.fn.expand("~/.config/nvim"))
print("   在 ~/.config/nvim 目录:")
local ok3, _ = pcall(require, "lsp")
print("     require 'lsp':", ok3 and "成功" or "失败")

-- 测试2: 在 ~/.config/nvim/lua 目录
vim.cmd("cd " .. vim.fn.expand("~/.config/nvim/lua"))
print("   在 ~/.config/nvim/lua 目录:")
local ok4, _ = pcall(require, "lsp")
print("     require 'lsp':", ok4 and "成功" or "失败")

-- 恢复目录
vim.cmd("cd " .. original_dir)

-- 6. 手动添加路径测试
print("\n6. 手动添加路径测试:")
local custom_path = vim.fn.expand("~/.config/nvim/lua/?.lua")
package.path = custom_path .. ";" .. package.path

local ok5, lsp_module2 = pcall(require, "lsp")
if ok5 then
  print("   ✓ 添加路径后 require 'lsp' 成功")
  print("   模块类型:", type(lsp_module2))
else
  print("   ✗ 添加路径后 require 'lsp' 失败:", lsp_module2)
end

print("\n=== 测试完成 ===")