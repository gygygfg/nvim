-- YAML语言服务器配置
return {
  name = "yamlls",
  cmd = { "yaml-language-server", "--stdio" },
  settings = {
    yaml = {
      validate = true,
      format = {
        enable = true,
      },
      completion = true,
      hover = true,
      schemaStore = {
        enable = true,
        url = 'https://www.schemastore.org/api/json/catalog.json',
      },
    },
  },
  root_markers = { '.git' },
  filetypes = { "yaml", "yml" },
}
