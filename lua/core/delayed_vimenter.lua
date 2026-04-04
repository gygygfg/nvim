-- 延迟 VimEnter 事件处理模块
-- 提供统一的接口让其他配置文件在插件加载完成后执行代码

local M = {}

-- 注册延迟的 VimEnter 回调
M.on_plugins_loaded = function(callback)
  -- 尝试使用 plugins 模块的回调机制
  local plugins_ok, plugins = pcall(require, "plugins")
  if plugins_ok then
    plugins.on_plugins_loaded(callback)
  else
    -- 如果 plugins 模块不可用，直接执行回调
    vim.schedule(callback)
  end
end

-- 检查插件是否已加载完成
M.plugins_loaded = function()
  local plugins_ok, plugins = pcall(require, "plugins")
  if plugins_ok then
    return plugins.plugins_loaded or false
  end
  return false
end

-- 等待插件加载完成的辅助函数
M.wait_for_plugins = function(callback, timeout)
  timeout = timeout or 10000 -- 默认10秒超时
  
  local start_time = vim.loop.now()
  local check_interval = 100 -- 每100毫秒检查一次
  
  local function check()
    if M.plugins_loaded() then
      vim.schedule(callback)
      return
    end
    
    -- 检查是否超时
    if vim.loop.now() - start_time > timeout then
      vim.notify("等待插件加载超时", vim.log.levels.WARN)
      vim.schedule(callback) -- 超时后仍然执行回调
      return
    end
    
    -- 继续等待
    vim.defer_fn(check, check_interval)
  end
  
  -- 开始检查
  check()
end

-- 创建延迟的 VimEnter 自动命令
M.create_delayed_autocmd = function(callback, opts)
  opts = opts or {}
  local pattern = opts.pattern or "*"
  local once = opts.once or false
  local group = opts.group
  
  -- 创建自动命令组（如果需要）
  local autocmd_group
  if group then
    autocmd_group = vim.api.nvim_create_augroup(group, { clear = true })
  end
  
  -- 创建自动命令
  vim.api.nvim_create_autocmd("VimEnter", {
    pattern = pattern,
    once = once,
    group = autocmd_group,
    callback = function()
      M.on_plugins_loaded(callback)
    end
  })
end

-- 导出模块
return M