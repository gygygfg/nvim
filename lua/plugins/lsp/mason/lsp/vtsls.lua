-- Mason lsp 配置
-- vtsls 配置

return {
    cmd = { "vtsls", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    single_file_support = true
}
