-- CodeCompanion 最小修复模块
-- 避免 "Invalid buffer id" 错误的最简单方案

local M = {}

-- 安全地执行函数，捕获缓冲区错误
local function safe_execute(fn)
  local ok, err = pcall(fn)
  if not ok then
    -- 检查是否是缓冲区无效错误
    if string.find(tostring(err), "Invalid buffer id") then
      -- 静默处理缓冲区错误
      return
    end
    -- 重新抛出其他错误
    error(err)
  end
end

-- 包装 vim.schedule 函数
local function wrap_vim_schedule()
  local original_schedule = vim.schedule
  vim.schedule = function(fn)
    return original_schedule(function()
      safe_execute(fn)
    end)
  end
end

-- 包装 vim.schedule_wrap 函数
local function wrap_vim_schedule_wrap()
  if vim.schedule_wrap then
    local original_schedule_wrap = vim.schedule_wrap
    vim.schedule_wrap = function(fn)
      local wrapped = original_schedule_wrap(fn)
      return function()
        safe_execute(wrapped)
      end
    end
  end
end

-- 猴子补丁 UI 模块的关键方法
local function patch_ui_methods()
  -- 延迟执行，等待模块加载
  vim.defer_fn(function()
    -- 尝试加载 UI 模块
    local ok, ui = pcall(require, "codecompanion.interactions.chat.ui")
    if not ok then
      -- 重试
      vim.defer_fn(patch_ui_methods, 500)
      return
    end
    
    -- 获取元表
    local mt = getmetatable(ui)
    if not mt then
      mt = {}
      setmetatable(ui, mt)
    end
    
    if not mt.__index then
      mt.__index = {}
    end
    
    -- 修复 lock_buf 方法
    local original_lock_buf = mt.__index.lock_buf
    if original_lock_buf then
      mt.__index.lock_buf = function(self)
        if vim.api.nvim_buf_is_valid(self.chat_bufnr) then
          return original_lock_buf(self)
        end
      end
    end
    
    -- 修复 unlock_buf 方法
    local original_unlock_buf = mt.__index.unlock_buf
    if original_unlock_buf then
      mt.__index.unlock_buf = function(self)
        if vim.api.nvim_buf_is_valid(self.chat_bufnr) then
          return original_unlock_buf(self)
        end
      end
    end
    
    vim.notify("CodeCompanion 缓冲区修复已应用", vim.log.levels.INFO)
  end, 1000)
end

-- 初始化
function M.setup()
  -- 包装关键函数
  wrap_vim_schedule()
  wrap_vim_schedule_wrap()
  
  -- 修补 UI 方法
  patch_ui_methods()
  
  vim.notify("CodeCompanion 最小修复模块已启用", vim.log.levels.INFO)
end

return M