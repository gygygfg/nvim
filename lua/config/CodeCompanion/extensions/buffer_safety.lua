-- CodeCompanion 缓冲区安全包装模块
-- 防止 "Invalid buffer id" 错误导致程序崩溃

local M = {}

-- 安全地包装 UI 方法，防止缓冲区无效错误
function M.wrap_ui_methods()
  -- 获取原始的 UI 模块
  local ok, original_ui = pcall(require, "codecompanion.interactions.chat.ui")
  if not ok then
    vim.notify("无法加载 CodeCompanion UI 模块", vim.log.levels.WARN)
    return
  end

  -- 保存原始方法
  local original_lock_buf = original_ui.lock_buf
  local original_unlock_buf = original_ui.unlock_buf

  -- 包装 lock_buf 方法
  function original_ui:lock_buf()
    -- 检查缓冲区是否有效
    if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then
      vim.notify("尝试锁定无效的缓冲区: " .. tostring(self.chat_bufnr), vim.log.levels.DEBUG)
      return
    end
    return original_lock_buf(self)
  end

  -- 包装 unlock_buf 方法
  function original_ui:unlock_buf()
    -- 检查缓冲区是否有效
    if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then
      vim.notify("尝试解锁无效的缓冲区: " .. tostring(self.chat_bufnr), vim.log.levels.DEBUG)
      return
    end
    return original_unlock_buf(self)
  end

  -- 包装其他可能访问 chat_bufnr 的方法
  local original_methods = {
    "last",
    "render_headers",
    "display_tokens",
    "follow",
    "is_visible",
    "hide",
    "close",
  }

  for _, method_name in ipairs(original_methods) do
    local original_method = original_ui[method_name]
    if original_method and type(original_method) == "function" then
      original_ui[method_name] = function(self, ...)
        -- 对于需要缓冲区的方法，先检查缓冲区有效性
        if method_name ~= "is_visible" then -- is_visible 可能不需要缓冲区
          if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then
            vim.notify("尝试在无效缓冲区上调用 " .. method_name .. ": " .. tostring(self.chat_bufnr), vim.log.levels.DEBUG)
            return nil
          end
        end
        return original_method(self, ...)
      end
    end
  end

  vim.notify("CodeCompanion 缓冲区安全包装已启用", vim.log.levels.INFO)
end

-- 安全地执行缓冲区操作
function M.safe_buffer_op(bufnr, operation, ...)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("尝试在无效缓冲区上执行操作: " .. tostring(bufnr), vim.log.levels.DEBUG)
    return nil
  end
  
  local ok, result = pcall(operation, bufnr, ...)
  if not ok then
    vim.notify("缓冲区操作失败: " .. tostring(result), vim.log.levels.WARN)
    return nil
  end
  
  return result
end

-- 全局错误处理器
function M.setup_global_error_handler()
  -- 包装 vim.schedule 以捕获错误
  local original_schedule = vim.schedule
  vim.schedule = function(fn)
    return original_schedule(function()
      local ok, err = pcall(fn)
      if not ok then
        -- 检查是否是缓冲区无效错误
        if string.find(tostring(err), "Invalid buffer id") then
          vim.notify("捕获到缓冲区无效错误，已安全处理: " .. tostring(err), vim.log.levels.DEBUG)
          return
        end
        -- 其他错误仍然抛出
        error(err)
      end
    end)
  end

  -- 包装 vim.schedule_wrap
  local original_schedule_wrap = vim.schedule_wrap
  vim.schedule_wrap = function(fn)
    local wrapped = original_schedule_wrap(fn)
    return function(...)
      local ok, err = pcall(wrapped, ...)
      if not ok then
        if string.find(tostring(err), "Invalid buffer id") then
          vim.notify("捕获到缓冲区无效错误(schedule_wrap)，已安全处理: " .. tostring(err), vim.log.levels.DEBUG)
          return
        end
        error(err)
      end
    end
  end
end

-- 初始化函数
function M.setup()
  -- 延迟执行，确保 CodeCompanion 已加载
  vim.defer_fn(function()
    M.wrap_ui_methods()
    M.setup_global_error_handler()
  end, 1000) -- 1秒后执行
  
  vim.notify("CodeCompanion 缓冲区安全模块已加载", vim.log.levels.INFO)
end

return M