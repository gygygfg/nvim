-- Mason lsp 配置
-- gopls 配置

return {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    single_file_support = true
}
