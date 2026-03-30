-- Mason lsp 配置
-- html 配置

return {
    cmd = { "vscode-html-language-server", "--stdio" },
    filetypes = { "html" },
    single_file_support = true
}
