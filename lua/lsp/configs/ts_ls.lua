-- lua/lsp/configs/ts_ls.lua
-- TypeScript/JavaScript 语言服务器配置（使用 ts_ls 作为服务器名称）

return {
  name = "ts_ls",
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_dir = vim.fs.dirname(vim.fs.find({ "tsconfig.json", "jsconfig.json", "package.json", ".git" }, { upward = true })[1]),
  init_options = {
    preferences = {
      disableSuggestions = false,
      quotePreference = "single",
      includeCompletionsForModuleExports = true,
      includeCompletionsForImportStatements = true,
      includeAutomaticOptionalChainCompletions = true,
      includeCompletionsWithSnippetText = true,
      includeCompletionsWithClassMemberSnippets = true,
      includeCompletionsWithObjectLiteralMethodSnippets = true,
      useLabelDetailsInCompletionEntries = true,
      allowRenameOfImportPath = true,
      includePackageJsonAutoImports = "auto",
    },
  },
  settings = {
    javascript = {
      inlayHints = {
        includeInlayEnumMemberValueHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayParameterTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayVariableTypeHints = true,
      },
      suggest = {
        completeFunctionCalls = true,
      },
    },
    typescript = {
      inlayHints = {
        includeInlayEnumMemberValueHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayParameterTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayVariableTypeHints = true,
      },
      suggest = {
        completeFunctionCalls = true,
      },
    },
  },
  on_attach = function(client, bufnr)
    -- 启用文档格式化
    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.documentRangeFormattingProvider = true
    
    -- 设置按键映射
    local opts = { buffer = bufnr, noremap = true, silent = true }
    
    -- 重命名
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    
    -- 代码操作
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
    
    -- 格式化
    vim.keymap.set("n", "<leader>f", function()
      vim.lsp.buf.format({ async = true })
    end, opts)
  end,
}