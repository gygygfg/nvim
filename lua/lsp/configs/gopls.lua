-- Go语言服务器配置
return {
  name = "gopls",
  cmd = { "gopls" },
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        shadow = true,
      },
      staticcheck = true,
      gofumpt = true,
      completeUnimported = true,
    },
  },
  root_markers = { 'go.mod', '.git' },
  filetypes = { "go", "gomod" },
}
