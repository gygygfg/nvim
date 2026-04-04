-- Mason 包查找工具
-- 提供自动查找 Mason 安装包名的功能

local M = {}

-- 自定义通知函数
local function custom_notify(msg, level)
  level = level or vim.log.levels.INFO
  local opts = {
    title = "Mason Finder",
    timeout = 3000,
  }
  vim.notify(msg, level, opts)
end

-- 检查 Mason 是否可用
local function check_mason_available()
  local mason_ok, mason_err = pcall(require, 'mason')
  local registry_ok, registry_err = pcall(require, 'mason-registry')
  
  if not mason_ok then
    custom_notify("❌ Mason 未安装或加载失败: " .. tostring(mason_err), vim.log.levels.ERROR)
    return false
  end
  
  if not registry_ok then
    custom_notify("❌ Mason 注册表模块加载失败: " .. tostring(registry_err), vim.log.levels.ERROR)
    return false
  end
  
  return true
end

-- 1. 按名称精确查找包
function M.find_package_by_name(package_name)
  if not check_mason_available() then return nil end
  
  local registry = require("mason-registry")
  
  -- 调试：列出所有可用的包
  local all_packages = registry.get_all_package_specs()
  local available_packages = {}
  for name, _ in pairs(all_packages) do
    table.insert(available_packages, name)
  end
  
  -- 按字母排序以便查看
  table.sort(available_packages)
  
  local package = registry.get_package(package_name)
  if not package then
    custom_notify("❌ 未找到包: " .. package_name, vim.log.levels.WARN)
    custom_notify("📋 可用的包 (前20个): " .. table.concat(available_packages, ", ", 1, 20), vim.log.levels.INFO)
    return nil
  end
  
  return {
    name = package.name,
    description = package.spec.description or "无描述",
    version = package.spec.version or "未知版本",
    installed = package:is_installed(),
    outdated = package:is_outdated(),
    homepage = package.spec.homepage or "无主页",
    categories = package.spec.categories or {},
  }
end

-- 2. 按描述或关键词搜索包
function M.search_packages(keyword)
  if not check_mason_available() then return {} end
  
  local registry = require("mason-registry")
  local all_packages = registry.get_all_package_specs()
  
  local results = {}
  
  for _, pkg_spec in pairs(all_packages) do
    local match = false
    
    -- 检查名称匹配
    if pkg_spec.name:lower():find(keyword:lower()) then
      match = true
    end
    
    -- 检查描述匹配
    if pkg_spec.description and pkg_spec.description:lower():find(keyword:lower()) then
      match = true
    end
    
    -- 检查分类匹配
    if pkg_spec.categories then
      for _, category in ipairs(pkg_spec.categories) do
        if category:lower():find(keyword:lower()) then
          match = true
          break
        end
      end
    end
    
    if match then
      table.insert(results, {
        name = pkg_spec.name,
        description = pkg_spec.description or "无描述",
        categories = pkg_spec.categories or {},
      })
    end
  end
  
  return results
end

-- 3. 按分类查找包
function M.find_packages_by_category(category)
  if not check_mason_available() then return {} end
  
  local registry = require("mason-registry")
  local all_packages = registry.get_all_package_specs()
  
  local results = {}
  
  for _, pkg_spec in pairs(all_packages) do
    if pkg_spec.categories then
      for _, cat in ipairs(pkg_spec.categories) do
        if cat:lower() == category:lower() then
          table.insert(results, {
            name = pkg_spec.name,
            description = pkg_spec.description or "无描述",
            categories = pkg_spec.categories,
          })
          break
        end
      end
    end
  end
  
  return results
end

-- 4. 获取所有已安装的包
function M.get_installed_packages()
  if not check_mason_available() then return {} end
  
  local registry = require("mason-registry")
  local installed_packages = registry.get_installed_packages()
  
  local results = {}
  
  for _, pkg in ipairs(installed_packages) do
    table.insert(results, {
      name = pkg.name,
      version = pkg.spec.version or "未知版本",
      outdated = pkg:is_outdated(),
      homepage = pkg.spec.homepage or "无主页",
      categories = pkg.spec.categories or {},
    })
  end
  
  return results
end

-- 5. 获取所有可用的包
function M.get_all_packages()
  if not check_mason_available() then return {} end
  
  local registry = require("mason-registry")
  local all_packages = registry.get_all_package_specs()
  
  local results = {}
  
  for _, pkg_spec in pairs(all_packages) do
    table.insert(results, {
      name = pkg_spec.name,
      description = pkg_spec.description or "无描述",
      categories = pkg_spec.categories or {},
    })
  end
  
  return results
end

-- 6. 智能查找 LSP 服务器包名
function M.find_lsp_package(language)
  if not check_mason_available() then return nil end
  
  local language_map = {
    -- 编程语言到 LSP 包名的映射
    lua = "lua_ls",
    python = "pyright",
    javascript = "ts_ls",
    typescript = "ts_ls",
    go = "gopls",
    rust = "rust_analyzer",
    c = "clangd",
    cpp = "clangd",
    java = "jdtls",
    bash = "bashls",
    sh = "bashls",
    html = "html",
    css = "cssls",
    json = "jsonls",
    yaml = "yaml-language-server",
    markdown = "marksman",
    dockerfile = "dockerfile-language-server",
    sql = "sqlls",
    php = "intelephense",
    ruby = "solargraph",
    swift = "sourcekit",
    kotlin = "kotlin-language-server",
    scala = "metals",
    haskell = "hls",
    elixir = "elixir-ls",
    erlang = "erlang-ls",
    ocaml = "ocaml-lsp",
    r = "r-languageserver",
    julia = "julia-lsp",
    fortran = "fortls",
  }
  
  local package_name = language_map[language:lower()]
  if not package_name then
    -- 尝试通过搜索查找
    local results = M.search_packages(language .. " language server")
    if #results > 0 then
      package_name = results[1].name
    else
      -- 尝试更通用的搜索
      results = M.search_packages(language)
      if #results > 0 then
        package_name = results[1].name
      end
    end
  end
  
  if package_name then
    return M.find_package_by_name(package_name)
  end
  
  return nil
end

-- 7. 查找格式化工具
function M.find_formatter_package(language)
  if not check_mason_available() then return nil end
  
  local formatter_map = {
    lua = "stylua",
    python = "black",
    javascript = "prettier",
    typescript = "prettier",
    go = "gofumpt",
    rust = "rustfmt",
    c = "clang-format",
    cpp = "clang-format",
    java = "google-java-format",
    bash = "shfmt",
    sh = "shfmt",
    html = "prettier",
    css = "prettier",
    json = "prettier",
    yaml = "prettier",
    markdown = "prettier",
    sql = "sql-formatter",
    php = "php-cs-fixer",
    ruby = "rubocop",
    swift = "swift-format",
    kotlin = "ktlint",
  }
  
  local package_name = formatter_map[language:lower()]
  if not package_name then
    -- 尝试通过搜索查找
    local results = M.search_packages(language .. " formatter")
    if #results > 0 then
      package_name = results[1].name
    else
      results = M.search_packages("format " .. language)
      if #results > 0 then
        package_name = results[1].name
      end
    end
  end
  
  if package_name then
    return M.find_package_by_name(package_name)
  end
  
  return nil
end

-- 8. 查找代码检查工具
function M.find_linter_package(language)
  if not check_mason_available() then return nil end
  
  local linter_map = {
    python = "pylint",
    javascript = "eslint",
    typescript = "eslint",
    go = "golangci-lint",
    rust = "clippy",
    bash = "shellcheck",
    sh = "shellcheck",
    dockerfile = "hadolint",
    yaml = "yamllint",
    markdown = "markdownlint",
    sql = "sqlfluff",
    php = "phpstan",
    ruby = "rubocop",
    swift = "swiftlint",
    kotlin = "detekt",
  }
  
  local package_name = linter_map[language:lower()]
  if not package_name then
    -- 尝试通过搜索查找
    local results = M.search_packages(language .. " linter")
    if #results > 0 then
      package_name = results[1].name
    else
      results = M.search_packages("lint " .. language)
      if #results > 0 then
        package_name = results[1].name
      end
    end
  end
  
  if package_name then
    return M.find_package_by_name(package_name)
  end
  
  return nil
end

-- 9. 查找调试适配器
function M.find_dap_package(language)
  if not check_mason_available() then return nil end
  
  local dap_map = {
    python = "debugpy",
    javascript = "js-debug-adapter",
    typescript = "js-debug-adapter",
    go = "delve",
    rust = "codelldb",
    c = "codelldb",
    cpp = "codelldb",
    java = "java-debug-adapter",
    lua = "local-lua-debugger-vscode",
  }
  
  local package_name = dap_map[language:lower()]
  if not package_name then
    -- 尝试通过搜索查找
    local results = M.search_packages(language .. " debug")
    if #results > 0 then
      package_name = results[1].name
    else
      results = M.search_packages("debug adapter " .. language)
      if #results > 0 then
        package_name = results[1].name
      end
    end
  end
  
  if package_name then
    return M.find_package_by_name(package_name)
  end
  
  return nil
end

-- 10. 综合查找工具链
function M.find_toolchain(language)
  if not check_mason_available() then return {} end
  
  local toolchain = {
    language = language,
    lsp = M.find_lsp_package(language),
    formatter = M.find_formatter_package(language),
    linter = M.find_linter_package(language),
    dap = M.find_dap_package(language),
  }
  
  return toolchain
end

-- 11. 刷新注册表缓存
function M.refresh_registry()
  if not check_mason_available() then return false end
  
  local registry = require("mason-registry")
  
  custom_notify("🔄 正在刷新 Mason 注册表...", vim.log.levels.INFO)
  
  local success = false
  registry.refresh(function()
    success = true
    custom_notify("✅ Mason 注册表已刷新", vim.log.levels.INFO)
  end)
  
  return success
end

-- 12. 检查包更新
function M.check_updates()
  if not check_mason_available() then return {} end
  
  local registry = require("mason-registry")
  local installed_packages = registry.get_installed_packages()
  
  local outdated_packages = {}
  
  for _, pkg in ipairs(installed_packages) do
    if pkg:is_outdated() then
      table.insert(outdated_packages, {
        name = pkg.name,
        current_version = pkg.spec.version or "未知",
        latest_version = pkg:get_latest_version() or "未知",
      })
    end
  end
  
  return outdated_packages
end

-- 13. 创建命令
function M.create_commands()
  vim.api.nvim_create_user_command("MasonFind", function(opts)
    local args = opts.fargs
    if #args == 0 then
      custom_notify("用法: MasonFind <包名|语言|关键词>", vim.log.levels.INFO)
      return
    end
    
    local query = table.concat(args, " ")
    
    -- 尝试按名称查找
    local package = M.find_package_by_name(query)
    if package then
      custom_notify("✅ 找到包: " .. package.name .. " - " .. package.description, vim.log.levels.INFO)
      return
    end
    
    -- 尝试按语言查找 LSP
    local lsp_package = M.find_lsp_package(query)
    if lsp_package then
      custom_notify("✅ 找到 LSP 包: " .. lsp_package.name .. " - " .. lsp_package.description, vim.log.levels.INFO)
      return
    end
    
    -- 尝试搜索
    local results = M.search_packages(query)
    if #results > 0 then
      local msg = "🔍 找到 " .. #results .. " 个相关包:\n"
      for i, pkg in ipairs(results) do
        if i <= 5 then  -- 只显示前5个结果
          msg = msg .. "  • " .. pkg.name .. " - " .. pkg.description .. "\n"
        end
      end
      if #results > 5 then
        msg = msg .. "  ... 还有 " .. (#results - 5) .. " 个结果"
      end
      custom_notify(msg, vim.log.levels.INFO)
      return
    end
    
    custom_notify("❌ 未找到匹配的包: " .. query, vim.log.levels.WARN)
  end, {
    nargs = "*",
    complete = function()
      -- 提供包名补全
      local packages = M.get_all_packages()
      local names = {}
      for _, pkg in ipairs(packages) do
        table.insert(names, pkg.name)
      end
      return names
    end,
  })
  
  vim.api.nvim_create_user_command("MasonInstalled", function()
    local packages = M.get_installed_packages()
    if #packages == 0 then
      custom_notify("📦 未安装任何 Mason 包", vim.log.levels.INFO)
      return
    end
    
    local msg = "📦 已安装 " .. #packages .. " 个包:\n"
    for _, pkg in ipairs(packages) do
      local status = pkg.outdated and "🔄 可更新" or "✅ 已安装"
      msg = msg .. "  • " .. pkg.name .. " (" .. pkg.version .. ") - " .. status .. "\n"
    end
    custom_notify(msg, vim.log.levels.INFO)
  end, {})
  
  vim.api.nvim_create_user_command("MasonToolchain", function(opts)
    local args = opts.fargs
    if #args == 0 then
      custom_notify("用法: MasonToolchain <语言>", vim.log.levels.INFO)
      return
    end
    
    local language = args[1]
    local toolchain = M.find_toolchain(language)
    
    if not toolchain.lsp and not toolchain.formatter and not toolchain.linter and not toolchain.dap then
      custom_notify("❌ 未找到 " .. language .. " 的工具链", vim.log.levels.WARN)
      return
    end
    
    local msg = "🔧 " .. language .. " 工具链:\n"
    
    if toolchain.lsp then
      msg = msg .. "  • LSP: " .. toolchain.lsp.name .. " - " .. toolchain.lsp.description .. "\n"
    end
    
    if toolchain.formatter then
      msg = msg .. "  • 格式化: " .. toolchain.formatter.name .. " - " .. toolchain.formatter.description .. "\n"
    end
    
    if toolchain.linter then
      msg = msg .. "  • 代码检查: " .. toolchain.linter.name .. " - " .. toolchain.linter.description .. "\n"
    end
    
    if toolchain.dap then
      msg = msg .. "  • 调试器: " .. toolchain.dap.name .. " - " .. toolchain.dap.description .. "\n"
    end
    
    custom_notify(msg, vim.log.levels.INFO)
  end, {})
  
  vim.api.nvim_create_user_command("MasonRefresh", function()
    M.refresh_registry()
  end, {})
  
  vim.api.nvim_create_user_command("MasonCheckUpdates", function()
    local updates = M.check_updates()
    if #updates == 0 then
      custom_notify("✅ 所有包都是最新版本", vim.log.levels.INFO)
      return
    end
    
    local msg = "🔄 有 " .. #updates .. " 个包可更新:\n"
    for _, pkg in ipairs(updates) do
      msg = msg .. "  • " .. pkg.name .. ": " .. pkg.current_version .. " → " .. pkg.latest_version .. "\n"
    end
    custom_notify(msg, vim.log.levels.INFO)
  end, {})
end

-- 14. 初始化函数
function M.setup()
  -- 创建命令
  M.create_commands()
  
  custom_notify("✅ Mason Finder 已加载", vim.log.levels.INFO)
end

return M