-- lua/lsp/ftplugin/javascript.lua
-- JavaScript 文件类型触发 LSP 配置

-- 防止重复配置
if vim.b.lsp_configured then
  return
end
vim.b.lsp_configured = true

-- 加载 tsserver 配置
local config = require('lsp.configs.tsserver')

-- 启用 tsserver 服务器并应用配置
vim.lsp.config('tsserver', config)
vim.lsp.enable('tsserver')
