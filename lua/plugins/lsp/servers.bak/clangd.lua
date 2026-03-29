-- Mason 安装: clangd
return {
  capabilities = capabilities, -- 从基础配置传入
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--fallback-style=llvm"
  },
  filetypes = {"c", "cpp", "objc", "objcpp"},
  single_file_support = true,
}
