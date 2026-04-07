-- ~/.config/nvim/lua/lsp/ftplugin/lua.lua
local lsp = require("lsp")

-- 启用 lua_ls 服务器
lsp.enable_server("lua_ls")

-- 可选：Lua 特定设置
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true
