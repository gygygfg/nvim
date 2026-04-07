-- lua/lsp/configs/tsserver.lua
-- TypeScript/JavaScript 语言服务器配置

return {
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
}
