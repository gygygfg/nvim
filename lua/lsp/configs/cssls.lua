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
  root_dir = vim.fs.dirname(vim.fs.find({ 'package.json', '.git' }, { upward = true })[1]),
  filetypes = { "css", "scss", "less" },
}
