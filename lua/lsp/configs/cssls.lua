-- CSS语言服务器配置
return {
  name = "cssls",
  cmd = { "vscode-css-language-server", "--stdio" },
  settings = {
    css = {
      validate = true,
      lint = {
        unknownAtRules = 'ignore',
      },
    },
    scss = {
      validate = true,
      lint = {
        unknownAtRules = 'ignore',
      },
    },
    less = {
      validate = true,
      lint = {
        unknownAtRules = 'ignore',
      },
    },
  },
  root_markers = { 'package.json', '.git' },
  filetypes = { "css", "scss", "less" },
}
