-- TypeScript/JavaScript 语言服务器配置
vim.lsp.config('ts_ls', {
  filetypes = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
  settings = {
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all'
      }
    },
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all'
      }
    }
  },
})