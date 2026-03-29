-- Mason lsp 配置
-- 迁移自: servers/vtsls.lua
-- 时间: 2026-03-29 20:37:04

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
