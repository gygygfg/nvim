-- HTML 语言服务器配置
vim.lsp.config('html', {
  cmd = { 'vscode-html-language-server', '--stdio' },
  filetypes = { 'html' },
  root_markers = { '.git' },
  settings = {
    html = {
      suggest = {
        html5 = true,
      },
    },
  },
})