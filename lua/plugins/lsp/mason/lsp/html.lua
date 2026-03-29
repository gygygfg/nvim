-- Mason lsp 配置
-- 迁移自: servers/html.lua
-- 时间: 2026-03-29 20:37:04

-- Mason 安装: vscode-html-language-server
return {
  capabilities = capabilities,
  filetypes = {"html", "htmldjango"},
  cmd = {"vscode-html-language-server", "--stdio"},
  init_options = {
    configurationSection = {"html", "css", "javascript"},
    embeddedLanguages = {
      css = true,
      javascript = true
    },
    provideFormatter = true
  },
  single_file_support = true
}
