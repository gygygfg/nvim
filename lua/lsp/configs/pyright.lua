-- ~/.config/nvim/lua/lsp/configs/pyright.lua
return {
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
  root_dir = vim.fs.dirname(vim.fs.find({ "pyproject.toml", "setup.py", "requirements.txt", ".git" }, { upward = true })[1]),
}
