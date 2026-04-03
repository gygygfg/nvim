-- CodeCompanion 缓冲区修复模块
-- 直接修复 "Invalid buffer id" 错误

local M = {}

-- 检查并修复 UI 模块中的缓冲区访问
function M.fix_ui_module()
  -- 尝试加载 UI 模块
  local ok, ui_module = pcall(require, "codecompanion.interactions.chat.ui")
  if not ok then
    -- 如果模块不存在，等待并重试
    vim.defer_fn(function()
      M.fix_ui_module()
    end, 500)
    return
  end

  -- 获取 UI 类的元表
  local ui_meta = getmetatable(ui_module) or {}
  local ui_index = ui_meta.__index
  
  if not ui_index then
    vim.notify("无法获取 UI 模块的元表", vim.log.levels.WARN)
    return
  end

  -- 保存原始方法
  local original_lock_buf = ui_index.lock_buf
  local original_unlock_buf = ui_index.unlock_buf

  -- 修复 lock_buf 方法
  if original_lock_buf then
    ui_index.lock_buf = function(self)
      -- 检查缓冲区是否有效
      if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then
        return
      end
      return original_lock_buf(self)
    end
  end

  -- 修复 unlock_buf 方法
  if original_unlock_buf then
    ui_index.unlock_buf = function(self)
      -- 检查缓冲区是否有效
      if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then
        return
      end
      return original_unlock_buf(self)
    end
  end

  -- 修复其他可能访问缓冲区的方法
  local methods_to_fix = {
    "last",
    "render_headers",
    "display_tokens",
    "follow",
    "hide",
    "close",
  }

  for _, method_name in ipairs(methods_to_fix) do
    local original_method = ui_index[method_name]
    if original_method and type(original_method) == "function" then
      ui_index[method_name] = function(self, ...)
        if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then
          return nil
        end
        return original_method(self, ...)
      end
    end
  end

  vim.notify("CodeCompanion 缓冲区修复已应用", vim.log.levels.INFO)
end

-- 设置全局错误处理器
function M.setup_error_handler()
  -- 保存原始的 vim.schedule
  local original_schedule = vim.schedule
  
  -- 包装 vim.schedule 以捕获缓冲区错误
  vim.schedule = function(fn)
    return original_schedule(function()
      local ok, err = xpcall(fn, debug.traceback)
      if not ok then
        -- 检查是否是缓冲区无效错误
        if string.find(err, "Invalid buffer id") then
          -- 静默处理缓冲区无效错误
          return
        end
        -- 重新抛出其他错误
        error(err)
      end
    end)
  end
end

-- 初始化
function M.setup()
  -- 延迟修复，确保模块已加载
  vim.defer_fn(function()
    M.fix_ui_module()
    M.setup_error_handler()
  end, 1000)
  
  vim.notify("CodeCompanion 缓冲区修复模块已加载", vim.log.levels.INFO)
end

return M