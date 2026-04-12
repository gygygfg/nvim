-- Go文件类型LSP配置
if vim.b.lsp_config_loaded then
  return
end

-- 检查是否已安装gopls
local mason_ok, mason = pcall(require, "lsp.mason")
if mason_ok and not mason.is_installed("gopls") then
  vim.notify("gopls未安装，正在自动安装...", vim.log.levels.INFO)
  mason.install_server("gopls")
end

-- 加载gopls配置并启动
local config_ok, config = pcall(require, "lsp.configs.gopls")
if config_ok then
  vim.lsp.enable("gopls", config)
else
  -- 使用默认配置
  vim.lsp.enable("gopls", {})
end
