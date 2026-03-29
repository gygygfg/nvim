-- 迁移脚本：将现有配置迁移到新的 Mason 目录结构

local M = {}

local function custom_notify(msg, level)
  level = level or vim.log.levels.INFO
  local opts = {
    title = "Mason 迁移",
    timeout = 3000,
  }
  vim.notify(msg, level, opts)
end

-- 服务器名称到包名称的映射
local SERVER_TO_PACKAGE = {
  -- LSP 服务器
  ["bashls"] = "bash-language-server",
  ["biome"] = "biome",
  ["eslint"] = "eslint-lsp",
  ["gopls"] = "golangci-lint-lsp",
  ["html"] = "html-lsp",
  ["pyright"] = "pyright",
  ["taplo"] = "taplo",
  ["ts_ls"] = "typescript-language-server",
  ["vimls"] = "vim-language-server",
  ["vtsls"] = "vtsls",
  ["yamlls"] = "yaml-language-server",
  
  -- 其他可能的服务器
  ["lua_ls"] = "lua-language-server",
  ["clangd"] = "clangd",
  ["rust_analyzer"] = "rust-analyzer",
  ["ast_grep"] = "ast-grep",
}

-- 包类型判断
local function get_package_type(server_name)
  -- 根据服务器名称判断包类型
  local lsp_servers = {
    "bashls", "biome", "eslint", "gopls", "html", "pyright", "taplo",
    "ts_ls", "vimls", "vtsls", "yamlls", "lua_ls", "clangd", "rust_analyzer"
  }
  
  local linters = {
    "biome", "eslint"  -- 这些既是 LSP 也是 Linter
  }
  
  local formatters = {
    "biome", "taplo"  -- 这些既是 LSP 也是 Formatter
  }
  
  local types = {}
  
  -- 检查是否为 LSP
  for _, name in ipairs(lsp_servers) do
    if server_name == name then
      table.insert(types, "lsp")
      break
    end
  end
  
  -- 检查是否为 Linter
  for _, name in ipairs(linters) do
    if server_name == name then
      table.insert(types, "linter")
      break
    end
  end
  
  -- 检查是否为 Formatter
  for _, name in ipairs(formatters) do
    if server_name == name then
      table.insert(types, "formatter")
      break
    end
  end
  
  -- 如果没有找到类型，默认为 LSP
  if #types == 0 then
    table.insert(types, "lsp")
  end
  
  return types
end

-- 迁移单个服务器配置
local function migrate_server_config(server_name, old_path, new_base_dir)
  local old_file = old_path .. "/" .. server_name .. ".lua"
  
  if vim.fn.filereadable(old_file) == 0 then
    custom_notify("⚠️ 配置文件不存在: " .. old_file, vim.log.levels.WARN)
    return false
  end
  
  -- 读取旧配置文件
  local content = vim.fn.readfile(old_file)
  if not content or #content == 0 then
    custom_notify("❌ 无法读取配置文件: " .. old_file, vim.log.levels.ERROR)
    return false
  end
  
  -- 获取包类型
  local package_types = get_package_type(server_name)
  local package_name = SERVER_TO_PACKAGE[server_name] or server_name
  
  -- 为每种类型创建配置文件
  for _, pkg_type in ipairs(package_types) do
    local new_dir = new_base_dir .. "/" .. pkg_type
    local new_file = new_dir .. "/" .. server_name .. ".lua"
    
    -- 确保目录存在
    vim.fn.mkdir(new_dir, "p")
    
    -- 根据类型调整配置内容
    local new_content = {}
    for _, line in ipairs(content) do
      -- 这里可以根据类型进行内容调整
      -- 例如，对于 linter 和 formatter，可能需要不同的配置格式
      table.insert(new_content, line)
    end
    
    -- 添加包信息注释
    table.insert(new_content, 1, "-- Mason 包: " .. package_name)
    table.insert(new_content, 2, "-- 类型: " .. pkg_type)
    table.insert(new_content, 3, "-- 迁移自: " .. old_file)
    table.insert(new_content, 4, "")
    
    -- 写入新文件
    vim.fn.writefile(new_content, new_file)
    
    custom_notify("📄 迁移 " .. server_name .. " -> " .. pkg_type .. " 配置", vim.log.levels.INFO)
  end
  
  return true
end

-- 主迁移函数
function M.migrate_all()
  local old_servers_dir = vim.fn.stdpath("config") .. "/lua/plugins/lsp/servers"
  local new_mason_dir = vim.fn.stdpath("config") .. "/lua/plugins/lsp/mason"
  
  if vim.fn.isdirectory(old_servers_dir) == 0 then
    custom_notify("❌ 旧服务器目录不存在: " .. old_servers_dir, vim.log.levels.ERROR)
    return false
  end
  
  -- 扫描旧服务器目录
  local servers = {}
  local ok, iter, state = pcall(vim.loop.fs_scandir, old_servers_dir)
  if not ok then
    custom_notify("❌ 无法扫描目录: " .. old_servers_dir, vim.log.levels.ERROR)
    return false
  end
  
  while true do
    local name, type = vim.loop.fs_scandir_next(iter, state)
    if not name then break end
    
    if name:match("%.lua$") and not name:match("%.bak$") then
      local server_name = name:gsub("%.lua$", "")
      table.insert(servers, server_name)
    end
  end
  
  if #servers == 0 then
    custom_notify("⚠️ 没有找到可迁移的服务器配置", vim.log.levels.WARN)
    return false
  end
  
  custom_notify("🔄 开始迁移 " .. #servers .. " 个服务器配置", vim.log.levels.INFO)
  
  -- 迁移每个服务器
  local migrated_count = 0
  for _, server_name in ipairs(servers) do
    if migrate_server_config(server_name, old_servers_dir, new_mason_dir) then
      migrated_count = migrated_count + 1
    end
  end
  
  -- 创建迁移完成标记
  local migration_mark = new_mason_dir .. "/.migration_complete"
  vim.fn.writefile({ "迁移完成时间: " .. os.date("%Y-%m-%d %H:%M:%S") }, migration_mark)
  
  custom_notify("✅ 迁移完成: " .. migrated_count .. "/" .. #servers .. " 个配置已迁移", vim.log.levels.INFO)
  
  return {
    total = #servers,
    migrated = migrated_count,
    servers = servers
  }
end

-- 创建示例配置文件
function M.create_example_configs()
  local examples_dir = vim.fn.stdpath("config") .. "/lua/plugins/lsp/mason/config/examples"
  vim.fn.mkdir(examples_dir, "p")
  
  -- LSP 配置示例
  local lsp_example = examples_dir .. "/example_lsp.lua"
  vim.fn.writefile({
    "-- LSP 配置示例",
    "return {",
    "  capabilities = require('cmp_nvim_lsp').default_capabilities(),",
    "  on_attach = function(client, bufnr)",
    "    -- 在这里添加自定义的 on_attach 逻辑",
    "  end,",
    "  settings = {",
    "    -- LSP 特定的设置",
    "  }",
    "}"
  }, lsp_example)
  
  -- Linter 配置示例
  local linter_example = examples_dir .. "/example_linter.lua"
  vim.fn.writefile({
    "-- Linter 配置示例",
    "return {",
    "  cmd = { 'linter-executable' },",
    "  args = { '--format', 'json' },",
    "  stdin = true,",
    "  ignore_exitcode = true,",
    "  parser = function(output)",
    "    -- 解析 linter 输出",
    "    return {}",
    "  end",
    "}"
  }, linter_example)
  
  -- Formatter 配置示例
  local formatter_example = examples_dir .. "/example_formatter.lua"
  vim.fn.writefile({
    "-- Formatter 配置示例",
    "return {",
    "  cmd = { 'formatter-executable' },",
    "  args = { '--stdin', '--stdout' },",
    "  stdin = true,",
    "  cwd = require('null-ls.utils').root_pattern(",
    "    '.git',",
    "    'package.json',",
    "    'pyproject.toml'",
    "  )",
    "}"
  }, formatter_example)
  
  custom_notify("📚 示例配置文件已创建在: " .. examples_dir, vim.log.levels.INFO)
end

-- 显示迁移状态
function M.show_status()
  local old_dir = vim.fn.stdpath("config") .. "/lua/plugins/lsp/servers"
  local new_dir = vim.fn.stdpath("config") .. "/lua/plugins/lsp/mason"
  
  local status = {
    old_dir_exists = vim.fn.isdirectory(old_dir) == 1,
    new_dir_exists = vim.fn.isdirectory(new_dir) == 1,
    migration_complete = vim.fn.filereadable(new_dir .. "/.migration_complete") == 1
  }
  
  return status
end

return M