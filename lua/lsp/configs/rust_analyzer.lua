-- Rust语言服务器配置
return {
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        loadOutDirsFromCheck = true,
        buildScripts = {
          enable = true,
        },
      },
      procMacro = {
        enable = true,
      },
      diagnostics = {
        enable = true,
      },
      checkOnSave = true,
      check = {
        command = 'clippy',
      },
    },
  },
  root_dir = vim.fs.dirname(vim.fs.find({ 'Cargo.toml', '.git' }, { upward = true })[1]),
}
