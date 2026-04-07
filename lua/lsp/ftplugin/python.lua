-- Python文件类型LSP配置
if vim.b.lsp_config_loaded then
  return
end

-- 使用内置的vim.lsp.enable启动pyright
-- 注意：这需要pyright已通过Mason安装
vim.lsp.enable("pyright", {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})
