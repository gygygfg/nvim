-- Mason lsp 配置
-- vim-language-server 配置

return {
    cmd = { "vim-language-server", "--stdio" },
    filetypes = { "vim" },
    single_file_support = true
}
