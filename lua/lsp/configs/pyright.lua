-- ~/.config/nvim/lua/lsp/configs/pyright.lua
return {
  name = "pyright",
  cmd = { "pyright-langserver", "--stdio" },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        typeCheckingMode = "basic",
        useLibraryCodeForTypes = true,
      },
    },
  },
  root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
  filetypes = { "python" },
}
