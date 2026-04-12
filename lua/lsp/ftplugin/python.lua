-- Python文件类型LSP配置
if vim.b.lsp_config_loaded then
  return
end

-- 检查是否已安装pyright
local mason_ok, mason = pcall(require, "lsp.mason")
if mason_ok and not mason.is_installed("pyright") then
  vim.notify("pyright未安装，正在自动安装...", vim.log.levels.INFO)
  mason.install_server("pyright")
end

-- 加载pyright配置并启动
local config_ok, config = pcall(require, "lsp.configs.pyright")
if config_ok then
  vim.lsp.enable("pyright", config)
else
  -- 使用默认配置
  vim.lsp.enable("pyright", {})
end
