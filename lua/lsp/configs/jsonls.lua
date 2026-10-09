-- JSON语言服务器配置
return {
  name = "jsonls",
  cmd = { "vscode-json-language-server", "--stdio" },
  settings = {
    json = {
      validate = {
        enable = true,
      },
      format = {
        enable = true,
      },
      schemas = {
        {
          fileMatch = { 'package.json', '*.json' },
        },
      },
    },
  },
  root_markers = { 'package.json', '.git' },
  filetypes = { "json", "jsonc" },
}
