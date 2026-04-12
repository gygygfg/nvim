-- C++文件类型LSP配置
if vim.b.lsp_config_loaded then
  return
end

-- 检查是否已安装clangd
local mason_ok, mason = pcall(require, "lsp.mason")
if mason_ok and not mason.is_installed("clangd") then
  vim.notify("clangd未安装，正在自动安装...", vim.log.levels.INFO)
  mason.install_server("clangd")
end

-- 加载clangd配置并启动
local config_ok, config = pcall(require, "lsp.configs.clangd")
if config_ok then
  vim.lsp.enable("clangd", config)
else
  -- 使用默认配置
  vim.lsp.enable("clangd", {})
end
