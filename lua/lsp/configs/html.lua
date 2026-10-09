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
  root_markers = { 'package.json', '.git' },
  filetypes = { "html", "htm" },
}
