-- Mason lsp 配置
-- pyright 配置

return {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = "workspace",
          typeCheckingMode = "basic"
        }
      }
    },
    single_file_support = true
}
