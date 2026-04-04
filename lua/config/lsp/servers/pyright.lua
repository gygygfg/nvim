-- Python 语言服务器配置
-- 兼容 Neovim 0.12 的新 LSP API
return {
  cmd = {"pyright-langserver", "--stdio"},
  filetypes = {"python"},
  root_markers = {".git", "pyproject.toml", "setup.py"},
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "strict",
        autoSearchPaths = true,
      },
    },
  },
}