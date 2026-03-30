-- Mason lsp 配置
-- rust-analyzer 配置

return {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    settings = {
      rust_analyzer = {
        -- 启用单文件支持
        standalone = true,
        -- 禁用自动工作区发现
        checkOnSave = {
          command = "clippy"
        },
        cargo = {
          allFeatures = true
        },
        -- 单文件配置
        standaloneConfig = {
          enable = true
        }
      }
    },
    single_file_support = true
}
