-- 备用配置，用于没有专门配置的文件类型
if vim.b.lsp_config_loaded then
  return
end

local filetype = vim.bo.filetype
local mappings = {
  javascript = "tsserver",
  typescript = "tsserver",
  javascriptreact = "tsserver",
  typescriptreact = "tsserver",
  json = "jsonls",
  yaml = "yamlls",
  yml = "yamlls",
  css = "cssls",
  html = "html",
  sh = "bashls",
  zsh = "bashls",
  c = "clangd",
  cpp = "clangd",
  go = "gopls",
  rust = "rust_analyzer",
  lua = "lua_ls",
}

local server_name = mappings[filetype]
if server_name then
  -- 检查是否已安装
  local mason_ok, mason = pcall(require, "lsp.mason")
  if mason_ok and not mason.is_installed(server_name) then
    vim.notify(server_name .. "未安装，正在自动安装...", vim.log.levels.INFO)
    mason.install_server(server_name)
  end
  
  -- 尝试加载配置
  local config_path = "lsp.configs." .. server_name
  local config_ok, config = pcall(require, config_path)
  
  if config_ok then
    vim.lsp.enable(server_name, config)
  else
    vim.lsp.enable(server_name, {})
  end
end
