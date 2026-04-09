-- plugins-manager.lua
-- 动态加载 plugins 目录下的所有插件配置模块

local M = {}

local function load_module(name)
  -- 加载单个模块
  local ok, module = pcall(require, name)
  if ok then
    vim.notify(string.format("✅ 成功加载模块: %s", name), vim.log.levels.INFO)
    return true
  else
    vim.notify(string.format("❌ 无法加载模块: %s\n错误: %s", name, module), vim.log.levels.ERROR)
    return false
  end
end

function M.load_all_plugins()
  -- 动态加载 plugins 目录下的所有模块
  local config_dir = vim.fn.stdpath("config")
  local plugins_dir = config_dir .. "/lua/plugins"

  vim.notify("🚀 开始加载插件配置...", vim.log.levels.INFO)
  vim.notify("插件目录: " .. plugins_dir, vim.log.levels.DEBUG)

  local loaded_count = 0
  local failed_count = 0

  -- 1. 首先加载 plugins 目录下的所有 .lua 文件
  -- 使用不同的方法来查找文件
  local lua_files = {}

  -- 方法1: 使用 vim.fn.glob
  local glob_pattern = plugins_dir .. "/*.lua"
  -- vim.notify("查找模式: " .. glob_pattern, vim.log.levels.DEBUG)

  local files = vim.split(vim.fn.glob(glob_pattern), "\n")
  vim.notify("找到 " .. #files .. " 个 .lua 文件", vim.log.levels.DEBUG)

  for _, file in ipairs(files) do
    if file ~= "" then
      table.insert(lua_files, file)
      vim.notify("找到文件: " .. file, vim.log.levels.DEBUG)
    end
  end

  -- 如果没有找到文件，尝试手动列出目录
  if #lua_files == 0 then
    vim.notify("尝试手动列出目录...", vim.log.levels.DEBUG)
    local handle = vim.loop.fs_scandir(plugins_dir)
    if handle then
      while true do
        local name, type = vim.loop.fs_scandir_next(handle)
        if not name then
          break
        end

        if type == "file" and name:match("%.lua$") then
          local full_path = plugins_dir .. "/" .. name
          table.insert(lua_files, full_path)
          vim.notify("手动找到: " .. name, vim.log.levels.DEBUG)
        end
      end
    end
  end

  -- 加载找到的 .lua 文件
  for _, file in ipairs(lua_files) do
    local filename = vim.fn.fnamemodify(file, ":t")

    -- 跳过插件管理器自身
    if filename == "plugins-manager.lua" then
      vim.notify("跳过插件管理器: " .. filename, vim.log.levels.DEBUG)
      goto continue_file
    end

    local module_name = "plugins." .. filename:gsub("%.lua$", "")
    -- vim.notify("尝试加载模块: " .. module_name, vim.log.levels.DEBUG)

    if load_module(module_name) then
      loaded_count = loaded_count + 1
    else
      failed_count = failed_count + 1
    end

    ::continue_file::
  end

  -- 2. 然后加载特殊目录中的 init.lua
  local special_dirs = { "git", "CodeCompanion" }
  -- vim.notify("开始加载特殊目录模块...", vim.log.levels.DEBUG)

  for _, dir_name in ipairs(special_dirs) do
    local module_name = "plugins." .. dir_name
    -- vim.notify("尝试加载目录模块: " .. module_name, vim.log.levels.DEBUG)
    if load_module(module_name) then
      loaded_count = loaded_count + 1
    else
      failed_count = failed_count + 1
    end
  end

  vim.notify(
    string.format("✨ 插件加载完成! 成功: %d, 失败: %d", loaded_count, failed_count),
    vim.log.levels.INFO
  )
  return loaded_count, failed_count
end

function M.list_available_plugins()
  -- 列出所有可用的插件模块
  local config_dir = vim.fn.stdpath("config")
  local plugins_dir = config_dir .. "/lua/plugins"

  vim.notify("扫描插件目录: " .. plugins_dir, vim.log.levels.DEBUG)

  local plugins = {}

  -- 使用 glob 查找 .lua 文件
  local glob_pattern = plugins_dir .. "/*.lua"
  local files = vim.split(vim.fn.glob(glob_pattern), "\n")

  for _, file in ipairs(files) do
    if file ~= "" then
      local filename = vim.fn.fnamemodify(file, ":t")
      if filename ~= "plugins-manager.lua" then
        local module_name = "plugins." .. filename:gsub("%.lua$", "")
        table.insert(plugins, {
          name = module_name,
          type = "file",
          path = file,
        })
        vim.notify("发现插件文件: " .. module_name, vim.log.levels.DEBUG)
      end
    end
  end

  -- 添加特殊目录
  local special_dirs = { "git", "CodeCompanion" }
  for _, dir_name in ipairs(special_dirs) do
    local init_path = plugins_dir .. "/" .. dir_name .. "/init.lua"
    if vim.fn.filereadable(init_path) == 1 then
      table.insert(plugins, {
        name = "plugins." .. dir_name,
        type = "dir",
        path = init_path,
      })
      vim.notify("发现插件目录: plugins." .. dir_name, vim.log.levels.DEBUG)
    end
  end

  return plugins
end

function M.print_available_plugins()
  -- 自动检测并打印可用的插件
  local plugins = M.list_available_plugins()

  if #plugins == 0 then
    vim.notify("📭 plugins 目录下没有找到插件配置", vim.log.levels.WARN)
    vim.notify("插件目录: " .. vim.fn.stdpath("config") .. "/lua/plugins", vim.log.levels.DEBUG)
    return
  end

  vim.notify("📁 可用的插件配置:", vim.log.levels.INFO)
  for _, plugin in ipairs(plugins) do
    local type_icon = plugin.type == "file" and "📄" or "📁"
    vim.notify(string.format("  %s %s", type_icon, plugin.name))
  end
  vim.notify(string.format("共发现 %d 个插件配置", #plugins))
end

function M.load_plugins_with_order(order_list)
  -- 按顺序加载插件（如果有依赖关系）
  vim.notify("🔧 按指定顺序加载插件...", vim.log.levels.INFO)

  local loaded_count = 0
  local failed_count = 0

  for _, plugin_name in ipairs(order_list) do
    local module_name = "plugins." .. plugin_name
    if load_module(module_name) then
      loaded_count = loaded_count + 1
    else
      failed_count = failed_count + 1
    end
  end

  vim.notify(
    string.format("🎯 顺序加载完成! 成功: %d, 失败: %d", loaded_count, failed_count),
    vim.log.levels.INFO
  )
  return loaded_count, failed_count
end

function M.reload_plugin(plugin_name)
  -- 提供一个安全的重载函数
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

M.suggested_order = {
  -- 默认执行顺序（根据您的目录结构建议）
  "editor", -- 基础编辑器配置
  "theme", -- 主题
  "lualine", -- 状态栏
  "bufferline", -- 缓冲区标签
  "nvim_tree", -- 文件树
  "telescope", -- 文件查找
  "cmp", -- 补全
  "treesitter", -- 语法高亮
  "git", -- Git集成
  "CodeCompanion", -- AI助手
}

-- 自动初始化：当此模块被 require 时，可以选择是否自动加载
function M.setup(opts)
  -- 自动初始化：当此模块被 require 时，可以选择是否自动加载
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
