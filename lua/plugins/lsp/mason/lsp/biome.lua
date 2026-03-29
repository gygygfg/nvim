-- Mason lsp 配置
-- 迁移自: servers/biome.lua
-- 时间: 2026-03-29 20:37:04

return {
  cmd = { "biome", "lsp-proxy" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jupyter" },
  root_dir = require("lspconfig.util").root_pattern("biome.json"),
  single_file_support = true,
}
