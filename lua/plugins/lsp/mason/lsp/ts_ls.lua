-- Mason lsp 配置
-- typescript-language-server 配置

return {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    single_file_support = true
}
