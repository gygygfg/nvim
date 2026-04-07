-- ~/.config/nvim/lua/lsp/mason.lua
-- 简化的 Mason 辅助函数

local M = {}

-- 推荐的 LSP 服务器列表
M.recommended_servers = {
  "lua_ls",        -- Lua
  "pyright",       -- Python
  "tsserver",      -- TypeScript/JavaScript
  "html",          -- HTML
  "cssls",         -- CSS
  "jsonls",        -- JSON
  "yamlls",        -- YAML
  "bashls",        -- Bash
  "clangd",        -- C/C++
  "gopls",         -- Go
  "rust_analyzer", -- Rust
}

-- 检查服务器是否安装
function M.is_installed(server_name)
  local mason_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_ok then
    return false
  end
  
  local ok, pkg = pcall(mason_registry.get_package, server_name)
  if not ok then
    return false
  end
  
  return pkg:is_installed()
end

-- 获取已安装的服务器
function M.get_installed()
  local mason_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_ok then
    return {}
  end
  
  local installed = {}
  for _, server in ipairs(M.recommended_servers) do
    if M.is_installed(server) then
      table.insert(installed, server)
    end
  end
  
  return installed
end

function M.setup()
  -- 不需要额外的设置
end

return M
