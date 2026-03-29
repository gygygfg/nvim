-- Mason 安装: vtsls
return {
  capabilities = capabilities,
  filetypes = {
    "javascript", "javascriptreact", "javascript.jsx",
    "typescript", "typescriptreact", "typescript.tsx"
  },
  settings = {
    typescript = {
      preferences = {
        includePackageJsonAutoImports = "auto"
      }
    },
    vtsls = {
      autoUseWorkspaceTsdk = true
    }
  },
  single_file_support = true
}
