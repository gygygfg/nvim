-- Lua 语言服务器配置
-- 兼容 Neovim 0.12 的新 LSP API
return {
  cmd = {"lua-language-server"},
  filetypes = {"lua"},
  root_markers = {".git"},
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        globals = {"vim"},
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
}