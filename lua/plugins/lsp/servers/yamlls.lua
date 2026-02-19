-- Mason 安装: yaml-language-server
return {
  capabilities = capabilities,
  filetypes = {"yaml", "yml"},
  settings = {
    yaml = {
      schemas = {
        kubernetes = "/*.yaml", -- Kubernetes schema 匹配
        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        ["https://json.schemastore.org/docker-compose.json"] = "docker-compose*.yml"
      },
      format = {
        enable = true,
        singleQuote = true,
        bracketSpacing = true,
      },
      validate = true,
      completion = true,
      hover = true,
    }
  },
  single_file_support = true
}
