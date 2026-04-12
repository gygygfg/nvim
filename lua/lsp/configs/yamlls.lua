-- YAML语言服务器配置
return {
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
  root_dir = vim.fs.dirname(vim.fs.find({ '.git' }, { upward = true })[1]),
}
