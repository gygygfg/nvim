-- Mason lsp 配置
-- 迁移自: servers/ts_ls.lua
-- 时间: 2026-03-29 20:37:04

return {
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
    root_dir = require("lspconfig.util").root_pattern("package.json", "tsconfig.json"),
}

