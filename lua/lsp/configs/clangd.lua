-- C/C++语言服务器配置
return {
  name = "clangd",
  cmd = { 'clangd', '--background-index', '--clang-tidy', '--header-insertion=iwyu', '--completion-style=detailed' },
  root_dir = vim.fs.dirname(vim.fs.find({ 'compile_commands.json', 'compile_flags.txt', '.git' }, { upward = true })[1]),
  filetypes = { "c", "cpp", "objc", "objcpp" },
  capabilities = {
    offsetEncoding = 'utf-16',
  },
}
