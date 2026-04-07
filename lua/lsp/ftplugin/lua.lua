-- lua/lsp/ftplugin/lua.lua
-- Lua 文件类型触发 LSP 配置

-- 防止重复配置
if vim.b.lsp_configured then
  return
end
vim.b.lsp_configured = true

-- 加载 lua_ls 配置
local config = require('lsp.configs.lua_ls')

-- 启用 lua_ls 服务器并应用配置
vim.lsp.config('lua_ls', config)
vim.lsp.enable('lua_ls')
