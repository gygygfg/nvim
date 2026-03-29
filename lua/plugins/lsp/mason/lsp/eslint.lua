-- Mason lsp 配置
-- 迁移自: servers/eslint.lua
-- 时间: 2026-03-29 20:37:04

return {
      on_attach = function(client, bufnr)
          vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              callback = function()
                  vim.lsp.buf.format({ async = false })
              end,
          })
      end
}

