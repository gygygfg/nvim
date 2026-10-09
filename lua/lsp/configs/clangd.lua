-- C/C++语言服务器配置
return {
  name = "clangd",
  cmd = { 'clangd', '--background-index', '--clang-tidy', '--header-insertion=iwyu', '--completion-style=detailed' },
  root_markers = { 'compile_commands.json', 'compile_flags.txt', '.git' },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  capabilities = {
    offsetEncoding = 'utf-16',
  },
}
