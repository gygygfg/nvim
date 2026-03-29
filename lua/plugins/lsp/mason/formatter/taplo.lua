-- Mason formatter 配置
-- 迁移自: servers/taplo.lua
-- 时间: 2026-03-29 20:37:04

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
