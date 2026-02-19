-- CodeCompanion 简单修复模块
-- 最简单的缓冲区错误处理方案

local M = {}

-- 设置全局错误处理器
function M.setup_global_handler()
  -- 保存原始的错误处理器
  local default_error_handler = debug.traceback
  
  -- 设置新的错误处理器
  debug.traceback = function(err)
    local trace = default_error_handler(err)
    
    -- 检查是否是缓冲区无效错误
    if string.find(trace, "Invalid buffer id") then
      -- 返回一个安全的错误信息，不包含堆栈跟踪
      return "Buffer operation failed: buffer no longer valid (safely handled)"
    end
    
    return trace
  end
  
  -- 包装 vim.schedule 和相关函数
  local function wrap_schedule_function(original)
    return function(fn)
      return original(function()
        local ok, result = xpcall(fn, debug.traceback)
        
        if not ok then
          -- 检查是否是缓冲区错误
          if string.find(result, "Invalid buffer id") then
            -- 静默处理
            return
          end
          -- 重新抛出其他错误
          error(result)
        end
        
        return result
      end)
    end
  end
  
  -- 包装关键函数
  vim.schedule = wrap_schedule_function(vim.schedule)
  
  if vim.schedule_wrap then
    vim.schedule_wrap = wrap_schedule_function(vim.schedule_wrap)
  end
  
  if vim.defer_fn then
    local original_defer_fn = vim.defer_fn
    vim.defer_fn = function(fn, delay)
      return original_defer_fn(function()
        local ok, err = xpcall(fn, debug.traceback)
        if not ok and not string.find(err, "Invalid buffer id") then
          error(err)
        end
      end, delay)
    end
  end
end

-- 猴子补丁 UI 模块
function M.patch_ui_module()
  -- 使用定时器等待模块加载
  local timer = vim.loop.new_timer()
  timer:start(1000, 0, vim.schedule_wrap(function()
    timer:close()
    
    -- 尝试获取 UI 模块
    local ok, _ = pcall(require, "codecompanion")
    if not ok then
      vim.notify("CodeCompanion 模块未加载，重试...", vim.log.levels.DEBUG)
      M.patch_ui_module() -- 重试
      return
    end
    
    -- 尝试获取 UI 类
    local ui_ok, ui_module = pcall(require, "codecompanion.interactions.chat.ui")
    if not ui_ok then
      vim.notify("UI 模块未加载，重试...", vim.log.levels.DEBUG)
      M.patch_ui_module() -- 重试
      return
    end
    
    -- 获取或创建元表
    local mt = getmetatable(ui_module)
    if not mt then
      mt = {}
      setmetatable(ui_module, mt)
    end
    
    if not mt.__index then
      mt.__index = {}
    end
    
    -- 定义安全的缓冲区访问函数
    local function safe_buffer_access(self, operation)
      if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then
        return nil
      end
      return operation(self)
    end
    
    -- 修补关键方法
    local methods = {
      "lock_buf",
      "unlock_buf",
      "last",
      "render_headers",
      "display_tokens",
    }
    
    for _, method in ipairs(methods) do
      local original = mt.__index[method]
      if original then
        mt.__index[method] = function(self, ...)
          local args = {...}
          return safe_buffer_access(self, function()
            return original(self, unpack(args))
          end)
        end
      end
    end
    
    vim.notify("CodeCompanion UI 模块已安全修补", vim.log.levels.INFO)
  end))
end

-- 初始化
function M.setup()
  -- 设置全局错误处理器
  M.setup_global_handler()
  
  -- 尝试修补 UI 模块
  M.patch_ui_module()
  
  vim.notify("CodeCompanion 缓冲区错误简单修复已启用", vim.log.levels.INFO)
end

return M