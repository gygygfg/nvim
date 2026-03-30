-- Mason lsp 配置
-- bash-language-server 配置

return {
    cmd = { "bash-language-server", "start" },
    filetypes = { "sh", "bash", "zsh" },
    single_file_support = true
}
