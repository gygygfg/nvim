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

