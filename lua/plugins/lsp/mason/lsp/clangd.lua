-- Mason lsp 配置
-- clangd 配置

return {
    cmd = { "clangd", "--background-index", "--clang-tidy", "--suggest-missing-includes" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
    single_file_support = true
}
