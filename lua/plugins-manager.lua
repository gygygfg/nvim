-- plugins-manager.lua
-- 动态加载 plugins 目录下的所有插件配置模块

local M = {}

-- 加载单个模块
local function load_module(name, is_file)
  local ok, module = pcall(require, name)
  if ok then
    vim.notify(string.format("✅ 成功加载模块: %s", name), vim.log.levels.INFO)
    return true
  else
    local msg = is_file and "文件" or "模块"
    vim.notify(string.format("❌ 无法加载%s: %s\n错误: %s", msg, name, module), vim.log.levels.ERROR)
    return false
  end
end

-- 动态加载 plugins 目录下的所有模块
function M.load_all_plugins()
  local config_dir = vim.fn.stdpath("config")
  local plugins_dir = config_dir .. "/lua/plugins"
  
  vim.notify("🚀 开始加载插件配置...", vim.log.levels.INFO)
  
  -- 获取 plugins 目录下的所有文件和文件夹
  local items = vim.fs.find(function(name, path)
    return true
  end, { limit = math.huge, type = "file", path = plugins_dir })
  
  local directories = vim.fs.find(function(name, path)
    return true
  end, { limit = math.huge, type = "directory", path = plugins_dir })
  
  local loaded_count = 0
  local failed_count = 0
  
  -- 优先加载 .lua 文件
  for _, item in ipairs(items) do
    local filename = vim.fs.basename(item)
    
    -- 跳过插件管理器自身
    if filename == "plugins-manager.lua" then
      goto continue
    end
    
    -- 只处理 .lua 文件
    if filename:match("%.lua$") then
      local module_name = "plugins." .. filename:gsub("%.lua$", "")
      if load_module(module_name, true) then
        loaded_count = loaded_count + 1
      else
        failed_count = failed_count + 1
      end
    end
    
    ::continue::
  end
  
  -- 然后加载文件夹中的 init.lua
  for _, dir in ipairs(directories) do
    local dirname = vim.fs.basename(dir)
    
    -- 跳过某些特殊目录（如果有的话）
    if dirname == "git" or dirname == "CodeCompanion" then
      -- 检查目录中是否有 init.lua
      local init_path = dir .. "/init.lua"
      if vim.fn.filereadable(init_path) == 1 then
        local module_name = "plugins." .. dirname
        if load_module(module_name, false) then
          loaded_count = loaded_count + 1
        else
          failed_count = failed_count + 1
        end
      end
    end
  end
  
  vim.notify(string.format("✨ 插件加载完成! 成功: %d, 失败: %d", loaded_count, failed_count), vim.log.levels.INFO)
  return loaded_count, failed_count
end

-- 按顺序加载插件（如果有依赖关系）
function M.load_plugins_with_order(order_list)
  vim.notify("🔧 按指定顺序加载插件...", vim.log.levels.INFO)
  
  local loaded_count = 0
  local failed_count = 0
  
  for _, plugin_name in ipairs(order_list) do
    local module_name = "plugins." .. plugin_name
    if load_module(module_name, false) then
      loaded_count = loaded_count + 1
    else
      failed_count = failed_count + 1
    end
  end
  
  vim.notify(string.format("🎯 顺序加载完成! 成功: %d, 失败: %d", loaded_count, failed_count), vim.log.levels.INFO)
  return loaded_count, failed_count
end

-- 列出所有可用的插件模块
function M.list_available_plugins()
  local config_dir = vim.fn.stdpath("config")
  local plugins_dir = config_dir .. "/lua/plugins"
  
  local plugins = {}
  
  -- 查找 .lua 文件
  local files = vim.fs.find("*.lua", { limit = math.huge, path = plugins_dir })
  for _, file in ipairs(files) do
    local filename = vim.fs.basename(file)
    if filename ~= "plugins-manager.lua" then
      local module_name = "plugins." .. filename:gsub("%.lua$", "")
      table.insert(plugins, { name = module_name, type = "file" })
    end
  end
  
  -- 查找文件夹中的 init.lua
  local dirs = vim.fs.find("*", { limit = math.huge, type = "directory", path = plugins_dir })
  for _, dir in ipairs(dirs) do
    local init_path = dir .. "/init.lua"
    if vim.fn.filereadable(init_path) == 1 then
      local dirname = vim.fs.basename(dir)
      table.insert(plugins, { name = "plugins." .. dirname, type = "dir" })
    end
  end
  
  return plugins
end

-- 自动检测并打印可用的插件
function M.print_available_plugins()
  local plugins = M.list_available_plugins()
  
  if #plugins == 0 then
    vim.notify("📭 plugins 目录下没有找到插件配置", vim.log.levels.WARN)
    return
  end
  
  vim.notify("📁 可用的插件配置:", vim.log.levels.INFO)
  for _, plugin in ipairs(plugins) do
    local type_icon = plugin.type == "file" and "📄" or "📁"
    print(string.format("  %s %s", type_icon, plugin.name))
  end
end

-- 提供一个安全的重载函数
function M.reload_plugin(plugin_name)
  local full_name = "plugins." .. plugin_name
  
  -- 先从 package.loaded 中移除模块
  package.loaded[full_name] = nil
  
  vim.notify(string.format("🔄 重新加载插件: %s", full_name), vim.log.levels.INFO)
  
  local ok, result = pcall(require, full_name)
  if ok then
    vim.notify(string.format("✅ 成功重载: %s", full_name), vim.log.levels.INFO)
    return true
  else
    vim.notify(string.format("❌ 重载失败: %s\n错误: %s", full_name, result), vim.log.levels.ERROR)
    return false
  end
end

-- 默认执行顺序（根据您的目录结构建议）
M.suggested_order = {
  "editor",      -- 基础编辑器配置
  "theme",       -- 主题
  "lualine",     -- 状态栏
  "bufferline",  -- 缓冲区标签
  "nvim_tree",   -- 文件树
  "telescope",   -- 文件查找
  "cmp",         -- 补全
  "treesitter",  -- 语法高亮
  "git",         -- Git集成
  "CodeCompanion"-- AI助手
}

-- 自动初始化：当此模块被 require 时，可以选择是否自动加载
function M.setup(opts)
  opts = opts or {}
  
  if opts.auto_load then
    if opts.load_in_order then
      M.load_plugins_with_order(opts.order or M.suggested_order)
    else
      M.load_all_plugins()
    end
  end
  
  if opts.print_list then
    M.print_available_plugins()
  end
end

return M
