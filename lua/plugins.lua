-- lua/plugins.lua
-- ============================================
-- 异步配置文件加载 - 新版加载机制
-- ============================================

local uv = vim.loop
local M = {}

-- 全局加载包装函数，让子文件能访问到
_G.load = {}

-- 全局收集器，用于存储所有配置文件的加载信息
M.global_collector = {
  packs = {},
  autocmds = {},
  defer_fns = {},
  requires = {}
}

local function init_load_wrapper()
  -- 初始化加载包装函数（只初始化一次）
  -- 包装函数定义
  load.require = function(module_path, ...)
    table.insert(M.global_collector.requires, {
      module = module_path,
      args = {...}
    })
  end

  load.nvim_create_autocmd = function(event, opts)
    table.insert(M.global_collector.autocmds, {
      event = event,
      opts = opts
    })
  end

  load.defer_fn = function(callback, delay)
    table.insert(M.global_collector.defer_fns, {
      callback = callback,
      delay = delay or 0
    })
  end

  load.addPack = function(pack_spec)
    if type(pack_spec) == 'table' then
      -- 即使只有单个包也总是传入包数组，直接合并到包列表
      for _, pack in ipairs(pack_spec) do
        table.insert(M.global_collector.packs, pack)
      end
    end
  end

  local function execute_collected_tasks()
    -- 执行收集到的加载任务
    if #M.global_collector.packs > 0 then
      -- 1. 先添加所有包
      vim.pack.add(M.global_collector.packs)
    end

    for _, autocmd in ipairs(M.global_collector.autocmds) do
      -- 2. 注册所有 autocmd
      vim.api.nvim_create_autocmd(autocmd.event, autocmd.opts)
    end

    for _, defer_fn in ipairs(M.global_collector.defer_fns) do
      -- 3. 执行所有 defer_fn
      vim.defer_fn(defer_fn.callback, defer_fn.delay)
    end

    for _, req in ipairs(M.global_collector.requires) do
      -- 4. 最后执行所有 require(配置文件里已经异步加载的不要用load.require)
      local success, result = pcall(require, req.module)
      if success and type(result) == 'table' and result.setup then
        pcall(result.setup, unpack(req.args or {}))
      end
    end
  end

  return {
    execute_collected_tasks = execute_collected_tasks
  }
end

M.scan_config_files = function(callback)
  -- 异步扫描目录获取配置文件列表
  local fallback_configs = {
    -- 默认调用的配置文件
    'editor', 'git', 'icons', 'lsp', 'theme', 'telescope', 'tools', 'ui'
  }
  local current_file = debug.getinfo(1, 'S').source:sub(2)
  current_file = current_file:gsub('\\', '/')
  local current_dir = current_file:match('(.*/)')
  local config_dir = current_dir .. 'config'

  -- 先同步检查目录是否存在
  local stat = uv.fs_stat(config_dir)
  if not stat or stat.type ~= 'directory' then
    vim.notify('配置目录不存在: ' .. config_dir, vim.log.levels.WARN)
    -- 回退到已知配置列表
    callback(fallback_configs, '使用回退列表')
    return
  end

  -- 使用 scandir 遍历目录
  local handle, err = uv.fs_scandir(config_dir)
  if not handle then
    vim.notify('无法扫描config目录: ' .. tostring(err), vim.log.levels.WARN)
    callback(fallback_configs, '使用回退列表')
    return
  end

  local config_files = {}
  local dir_entries = {}

  -- 先收集所有条目
  while true do
    local name, type = uv.fs_scandir_next(handle)
    if not name then break end
    table.insert(dir_entries, {name = name, type = type})
  end

  -- 异步处理每个条目
  local total_entries = #dir_entries
  if total_entries == 0 then
    callback(config_files, nil)
    return
  end

  local processed = 0
  local pending_checks = 0

  local function check_completion()
    processed = processed + 1
    if processed >= total_entries and pending_checks == 0 then
      table.sort(config_files)
      callback(config_files, nil)
    end
  end

  for _, entry in ipairs(dir_entries) do
    local name = entry.name
    local entry_type = entry.type

    if entry_type == 'file' and name:match('%.lua$') then
      local config_name = name:gsub('%.lua$', '')
      if config_name ~= 'init' then
        table.insert(config_files, config_name)
      end
      check_completion()
    elseif entry_type == 'directory' then
      pending_checks = pending_checks + 1
      local subdir_path = config_dir .. '/' .. name
      local init_file = subdir_path .. '/init.lua'

      -- 异步检查init.lua是否存在
      uv.fs_stat(init_file, function(stat_err, init_stat)
        if not stat_err and init_stat and init_stat.type == 'file' then
          table.insert(config_files, name)
        end
        pending_checks = pending_checks - 1
        check_completion()
      end)
    else
      check_completion()
    end
  end
end

M.load_config_file = function(config_name, callback)
  -- 异步加载单个配置文件
  local module_path = 'config.' .. config_name

  -- 检查是否已加载
  if package.loaded[module_path] then
    callback(config_name, true, '已加载')
    return
  end

  -- 异步加载模块
  vim.schedule(function()
    local success, result_or_err = pcall(require, module_path)

    if success then
      package.loaded[module_path] = result_or_err or true
      callback(config_name, true, nil)
    else
      vim.notify('加载配置文件失败: ' .. config_name .. ' - ' .. tostring(result_or_err), vim.log.levels.WARN)
      callback(config_name, false, result_or_err)
    end
  end)
end

M.load_all_configs_async = function(on_progress, on_complete)
  -- 批量异步加载配置文件
  M.scan_config_files(function(config_files, scan_err)
    if scan_err and scan_err ~= '使用回退列表' then
      vim.notify('扫描配置目录时出错: ' .. scan_err, vim.log.levels.ERROR)
    end

    if #config_files == 0 then
      vim.notify('未找到任何配置文件', vim.log.levels.WARN)
      if on_complete then 
        vim.schedule(function()
          on_complete({}, 0, 0)
        end)
      end
      return
    end

    local total = #config_files
    local loaded = 0
    local failed = 0
    local results = {}

    local function update_progress()
      if on_progress then
        vim.schedule(function()
          on_progress(config_files, loaded, failed, total, results)
        end)
      end
    end

    local function config_loaded(name, success, err)
      if success then
        loaded = loaded + 1
        results[name] = { success = true }
      else
        failed = failed + 1
        results[name] = { success = false, error = err }
      end

      update_progress()

      -- 所有配置加载完成
      if loaded + failed >= total then
        vim.schedule(function()
          local msg = string.format('插件配置加载完成: %d成功, %d失败', loaded, failed)
          vim.notify(msg, vim.log.levels.INFO)
          if on_complete then
            on_complete(results, loaded, failed)
          end
        end)
      end
    end

    -- 并发加载配置文件
    local MAX_CONCURRENT = 2
    local current_index = 0
    local active_loads = 0

    local function start_next()
      while active_loads < MAX_CONCURRENT and current_index < total do
        current_index = current_index + 1
        active_loads = active_loads + 1

        local config_name = config_files[current_index]
        M.load_config_file(config_name, function(name, success, err)
          active_loads = active_loads - 1
          config_loaded(name, success, err)
          start_next()
        end)
      end
    end

    -- 开始加载
    vim.schedule(function()
      vim.notify('开始异步加载 ' .. total .. ' 个配置文件...', vim.log.levels.INFO)
      start_next()
    end)
  end)
end

M.load_all_configs_sync = function()
  -- 同步版本（兼容性，使用新的加载机制）
  local config_files = {}
  local current_file = debug.getinfo(1, 'S').source:sub(2)
  current_file = current_file:gsub('\\', '/')
  local current_dir = current_file:match('(.*/)')
  local config_dir = current_dir .. 'config'

  -- 同步扫描目录
  local handle = uv.fs_scandir(config_dir)
  if handle then
    while true do
      local name, type = uv.fs_scandir_next(handle)
      if not name then break end

      if type == 'file' and name:match('%.lua$') then
        local config_name = name:gsub('%.lua$', '')
        if config_name ~= 'init' then
          table.insert(config_files, config_name)
        end
      elseif type == 'directory' then
        local subdir_path = config_dir .. '/' .. name
        local init_file = subdir_path .. '/init.lua'
        local init_stat = uv.fs_stat(init_file)

        if init_stat and init_stat.type == 'file' then
          table.insert(config_files, name)
        end
      end
    end
  else
    vim.notify('无法扫描config目录，使用已知插件列表', vim.log.levels.INFO)
    config_files = {
      'editor', 'git', 'icons', 'lsp', 'theme', 'telescope', 'tools', 'ui'
    }
  end

  table.sort(config_files)

  -- 同步加载（使用新的加载机制）
  for _, config_name in ipairs(config_files) do
    local module_path = 'config.' .. config_name
    if not package.loaded[module_path] then
      local success, err = pcall(require, module_path)
      if not success then
        vim.notify('加载配置文件失败: ' .. config_name .. ' - ' .. tostring(err), vim.log.levels.WARN)
      end
    end
  end

  vim.notify('插件配置加载完成', vim.log.levels.INFO)
  return config_files
end

M.setup = function(opts)
  -- 主入口函数
  opts = opts or {}
  local on_progress = opts.on_progress
  local on_complete = opts.on_complete
  local use_async = opts.use_async ~= false

  -- 初始化加载包装器（只初始化一次）
  local loader = init_load_wrapper()

  if use_async then
    vim.defer_fn(function()
      M.load_all_configs_async(on_progress, function(results, loaded, failed)
        -- 所有配置文件加载完成后执行收集到的任务
        loader.execute_collected_tasks()

        if on_complete then
          on_complete(results, loaded, failed)
        end
      end)
    end, opts.delay or 50)
  else
    vim.schedule(function()
      M.load_all_configs_sync()
      -- 所有配置文件加载完成后执行收集到的任务
      loader.execute_collected_tasks()

      if on_complete then
        on_complete({}, #package.loaded, 0)
      end
    end)
  end
end

-- 导出模块
return M
