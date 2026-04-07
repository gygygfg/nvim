-- ~/.config/nvim/lua/lsp/check.lua
-- 检查 Mason 和 LSP 状态

local M = {}

function M.check_installation()
  -- 检查 Mason 是否安装
  local mason_ok, mason = pcall(require, "mason")
  if not mason_ok then
    print("❌ Mason 插件未安装")
    return false
  end
  
  print("✅ Mason 已安装")
  
  -- 检查 mason-lspconfig
  local mason_lspconfig_ok = pcall(require, "mason-lspconfig")
  if not mason_lspconfig_ok then
    print("⚠️  mason-lspconfig 未安装（可选）")
  else
    print("✅ mason-lspconfig 已安装")
  end
  
  -- 检查已安装的 LSP 服务器
  local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
  if mason_registry_ok then
    print("\n已安装的 LSP 包:")
    local installed = 0
    for _, pkg in ipairs(mason_registry.get_installed_packages()) do
      if pkg.spec.type == "lsp" then
        print("  ✓ " .. pkg.name)
        installed = installed + 1
      end
    end
    print("总计: " .. installed .. " 个 LSP 包")
  else
    print("❌ 无法访问 Mason 注册表")
  end
  
  return true
end

function M.check_lsp_status()
  print("\n当前缓冲区的 LSP 状态:")
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  
  if #clients == 0 then
    print("  没有活动的 LSP 客户端")
  else
    for _, client in ipairs(clients) do
      print("  ✓ " .. client.name)
    end
  end
  
  print("\n文件类型: " .. vim.bo.filetype)
  local filetype_to_lsp = require("lsp").filetype_to_lsp or {}
  local server_name = filetype_to_lsp[vim.bo.filetype]
  if server_name then
    print("对应的 LSP 服务器: " .. server_name)
  else
    print("没有配置对应的 LSP 服务器")
  end
end

-- 创建命令
vim.api.nvim_create_user_command("LspDebug", function()
  M.check_installation()
  M.check_lsp_status()
end, { desc = "调试 LSP 配置" })

return M
