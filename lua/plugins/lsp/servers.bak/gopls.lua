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
