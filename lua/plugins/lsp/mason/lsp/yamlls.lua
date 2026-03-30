-- Mason lsp 配置
-- yaml-language-server 配置

return {
    cmd = { "yaml-language-server", "--stdio" },
    filetypes = { "yaml", "yml" },
    single_file_support = true
}
