-- Mason lsp 配置
-- 迁移自: servers/gopls.lua
-- 时间: 2026-03-29 20:37:04

-- Mason 安装: gopls
return {
    capabilities = capabilities,
    filetypes = {"go", "gomod", "gowork", "gotmpl"},
    cmd = {"gopls", "serve"},
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
          shadow = true,
        },
        staticcheck = true,
        gofumpt = true, -- 如果安装了 gofumpt
        completeUnimported = true,
        usePlaceholders = true,
      },
    },
    single_file_support = true
}
