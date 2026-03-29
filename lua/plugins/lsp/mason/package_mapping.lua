-- Mason 包名映射
-- 将配置文件名映射到实际的 Mason 包名

local M = {}

-- 配置文件名到 Mason 包名的映射
M.SERVER_TO_PACKAGE = {
  -- LSP 服务器
  ["bashls"] = "bash-language-server",
  ["biome"] = "biome",
  ["eslint"] = "eslint-lsp",
  ["gopls"] = "gopls",  -- 修正：gopls 是正确的包名
  ["html"] = "html-lsp",
  ["pyright"] = "pyright",
  ["taplo"] = "taplo",
  ["ts_ls"] = "typescript-language-server",
  ["vimls"] = "vim-language-server",
  ["vtsls"] = "vtsls",
  ["yamlls"] = "yaml-language-server",
  
  -- 其他常见的 LSP 服务器
  ["lua_ls"] = "lua-language-server",
  ["clangd"] = "clangd",
  ["rust_analyzer"] = "rust-analyzer",
  ["ast_grep"] = "ast-grep",
  ["cssls"] = "css-lsp",
  ["dockerls"] = "dockerfile-language-server",
  ["jsonls"] = "json-lsp",
  ["tsserver"] = "typescript-language-server",
  ["sqlls"] = "sql-language-server",
  ["texlab"] = "texlab",
}

-- 包类型判断
M.PACKAGE_TYPES = {
  -- LSP 服务器
  LSP = {
    "bash-language-server", "biome", "eslint-lsp", "gopls",
    "html-lsp", "pyright", "taplo", "typescript-language-server",
    "vim-language-server", "vtsls", "yaml-language-server",
    "lua-language-server", "clangd", "rust-analyzer", "ast-grep",
    "css-lsp", "dockerfile-language-server", "json-lsp", "sql-language-server",
    "texlab"
  },
  
  -- DAP 调试器
  DAP = {
    "debugpy", "codelldb", "delve", "firefox-debug-adapter",
    "chrome-debug-adapter", "node-debug2-adapter"
  },
  
  -- Linter 代码检查器
  LINTER = {
    "biome", "eslint-lsp", "ruff", "shellcheck",
    "markdownlint", "yamllint", "jsonlint"
  },
  
  -- Formatter 代码格式化器
  FORMATTER = {
    "biome", "prettier", "black", "gofumpt", "stylua",
    "shfmt", "taplo", "rustfmt"
  }
}

-- 获取配置文件名对应的包名
function M.get_package_name(config_name)
  return M.SERVER_TO_PACKAGE[config_name] or config_name
end

-- 获取包的类型
function M.get_package_type(package_name)
  local types = {}
  
  for type_name, packages in pairs(M.PACKAGE_TYPES) do
    for _, pkg in ipairs(packages) do
      if pkg == package_name then
        table.insert(types, type_name:lower())
        break
      end
    end
  end
  
  -- 如果没有找到类型，默认为 LSP
  if #types == 0 then
    table.insert(types, "lsp")
  end
  
  return types
end

-- 获取配置文件的类型
function M.get_config_type(config_name)
  local package_name = M.get_package_name(config_name)
  return M.get_package_type(package_name)
end

-- 检查包是否可用
function M.is_package_available(package_name)
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return false
  end
  
  local pkg = registry.get_package(package_name)
  return pkg ~= nil
end

-- 获取所有可用的包
function M.get_available_packages()
  local registry = require("mason-registry")
  local packages = {}
  
  for config_name, package_name in pairs(M.SERVER_TO_PACKAGE) do
    if M.is_package_available(package_name) then
      packages[config_name] = {
        package_name = package_name,
        types = M.get_package_type(package_name),
        available = true
      }
    end
  end
  
  return packages
end

return M