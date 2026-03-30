-- Mason lsp 配置
-- lua-language-server 配置

return {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim" }
        },
        runtime = {
          version = "LuaJIT"
        },
        telemetry = {
          enable = false
        },
        workspace = {
          library = { vim.env.VIMRUNTIME },
          -- 避免扫描整个根目录
          checkThirdParty = false,
          maxPreload = 1000,
          preloadFileSize = 100
        }
      }
    },
    single_file_support = true
}
