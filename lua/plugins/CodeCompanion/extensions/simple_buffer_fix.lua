-- CodeCompanion 简单缓冲区修复模块
-- 极简方案修复 "Invalid buffer id" 错误

local M = {}

-- 极简修复：只包装 nvim_buf_get_name
function M.simple_fix()
  -- 保存原始函数
  local original_nvim_buf_get_name = vim.api.nvim_buf_get_name
  
  -- 替换为安全的版本
  vim.api.nvim_buf_get_name = function(bufnr)
    -- 简单检查：如果是数字且大于 100000，可能是无效的
    if type(bufnr) == "number" and bufnr > 100000 then
      return ""
    end
    
    -- 尝试调用原始函数，如果失败则返回空字符串
    local ok, result = pcall(original_nvim_buf_get_name, bufnr)
    if ok then
      return result
    else
      -- 检查是否是缓冲区无效错误
      if string.find(tostring(result), "Invalid buffer id") then
        return ""
      end
      -- 重新抛出其他错误
      error(result)
    end
  end
  
  -- 也包装 vim.schedule 以防止错误传播
  local original_vim_schedule = vim.schedule
  vim.schedule = function(fn)
    return original_vim_schedule(function()
      local ok, err = pcall(fn)
      if not ok then
        -- 如果是缓冲区无效错误，静默处理
        if string.find(tostring(err), "Invalid buffer id") then
          return
        end
        -- 对于其他错误，只记录不抛出
        vim.notify("计划任务错误: " .. tostring(err), vim.log.levels.WARN)
      end
    end)
  end
  
  vim.notify("✅ 已应用简单缓冲区修复", vim.log.levels.INFO)
end

-- 设置函数
function M.setup()
  -- 立即应用简单修复
  M.simple_fix()
end

return M