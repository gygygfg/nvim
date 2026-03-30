-- Mason lsp 配置
-- eslint 配置

return {
    cmd = { "vscode-eslint-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
    settings = {
      validate = "on",
      workingDirectory = {
        mode = "auto"
      }
    },
    single_file_support = true
}
