-- Rust文件类型LSP配置
if vim.b.lsp_config_loaded then
  return
end

-- 检查是否已安装rust_analyzer
local mason_ok, mason = pcall(require, "lsp.mason")
if mason_ok and not mason.is_installed("rust_analyzer") then
  vim.notify("rust_analyzer未安装，正在自动安装...", vim.log.levels.INFO)
  mason.install_server("rust_analyzer")
end

-- 加载rust_analyzer配置并启动
local config_ok, config = pcall(require, "lsp.configs.rust_analyzer")
if config_ok then
  vim.lsp.enable("rust_analyzer", config)
else
  -- 使用默认配置
  vim.lsp.enable("rust_analyzer", {})
end
