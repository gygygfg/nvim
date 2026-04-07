-- lua/lsp/configs/lua_ls.lua
-- Lua 语言服务器配置

return {
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      diagnostics = {
        globals = { 'vim' },
        disable = { 'different-requires' },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
      hint = {
        enable = true,
        setType = true,
        paramType = true,
        paramName = true,
        paramNamePrefix = "arg: ",
      },
    },
  },
}
