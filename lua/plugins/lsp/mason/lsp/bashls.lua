-- Mason lsp 配置
-- 迁移自: servers/bashls.lua
-- 时间: 2026-03-29 20:37:04

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
