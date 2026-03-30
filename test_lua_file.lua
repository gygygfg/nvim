-- 测试 Lua 语言服务器
local M = {}

function M.hello()
  print("Hello from Lua LSP test")
  return "Test successful"
end

-- 测试 vim 全局变量
vim.notify("Lua LSP test file loaded")

return M