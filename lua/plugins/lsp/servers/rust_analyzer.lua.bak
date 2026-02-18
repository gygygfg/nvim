-- Mason 安装: rust-analyzer
return {
  capabilities = capabilities,
  filetypes = {"rust"},
  cmd = {
    "rust-analyzer",
  },
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
        runBuildScripts = true,
      },
      checkOnSave = {
        command = "clippy",
        extraArgs = { "--no-deps" },
      },
      procMacro = {
        enable = true
      },
    }
  },
  single_file_support = true
}
