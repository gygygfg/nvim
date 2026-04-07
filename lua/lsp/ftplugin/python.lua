-- lua/lsp/ftplugin/python.lua
-- Python 文件类型触发 LSP 配置

-- 防止重复配置
if vim.b.lsp_configured then
  return
end
vim.b.lsp_configured = true

-- 加载 pyright 配置
local config = require('lsp.configs.pyright')

-- 启用 pyright 服务器并应用配置
vim.lsp.config('pyright', config)
vim.lsp.enable('pyright')
