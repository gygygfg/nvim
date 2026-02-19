-- Mason 安装: taplo
return {
  capabilities = capabilities,
  filetypes = {"toml"},
  cmd = {"taplo", "lsp", "stdio"},
  settings = {
    evenBetterToml = {
      schema = {
        enabled = true,
        repositoryEnabled = true
      }
    }
  },
  single_file_support = true
}
