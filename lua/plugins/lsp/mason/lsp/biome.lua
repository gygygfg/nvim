-- Mason lsp 配置
-- biome 配置

return {
    cmd = { "biome", "lsp-proxy" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json" },
    single_file_support = true
}
