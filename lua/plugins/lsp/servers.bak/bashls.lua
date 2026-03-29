-- Mason 安装: bash-language-server
return {
  capabilities = capabilities,
  filetypes = {"sh", "bash", "zsh"},
  cmd = { "bash-language-server", "start" },
  settings = {
    bashIde = {
      backgroundAnalysisMaxFiles = 500, -- 增加文件分析数量
      explainErrorMessages = true
    }
  },
  single_file_support = true
}
