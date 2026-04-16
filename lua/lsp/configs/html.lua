-- HTML语言服务器配置
return {
  name = "html",
  cmd = { "vscode-html-language-server", "--stdio" },
  settings = {
    html = {
      format = {
        templating = true,
        wrapLineLength = 120,
        wrapAttributes = 'auto',
      },
      suggest = {
        html5 = true,
      },
    },
  },
  root_dir = vim.fs.dirname(vim.fs.find({ 'package.json', '.git' }, { upward = true })[1]),
  filetypes = { "html", "htm" },
}
