-- Rust 语言服务器配置
vim.lsp.config('rust_analyzer', {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml' },
  settings = {
    ['rust-analyzer'] = {
      checkOnSave = {
        command = 'clippy'
      }
    }
  },
})