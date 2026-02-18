return {
      cmd = { "biome", "lsp-proxy" },
      filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json" },
      root_dir = require("lspconfig.util").root_pattern("biome.json"),
      single_file_support = true,
}
