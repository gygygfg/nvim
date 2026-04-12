-- Lua文件类型LSP配置
if vim.b.lsp_config_loaded then
  return
end

-- 检查是否已安装lua_ls
local mason_ok, mason = pcall(require, "lsp.mason")
if mason_ok and not mason.is_installed("lua_ls") then
  vim.notify("lua_ls未安装，正在自动安装...", vim.log.levels.INFO)
  mason.install_server("lua_ls")
end

-- 加载lua_ls配置并启动
local config_ok, config = pcall(require, "lsp.configs.lua_ls")
if config_ok then
  vim.lsp.enable("lua_ls", config)
else
  -- 使用默认配置
  vim.lsp.enable("lua_ls", {})
end
