-- CodeCompanion 最终修复模块
-- 最简单的缓冲区错误修复方案

local M = {}

-- 直接修复插件源码
function M.fix_source_code()
  local ui_file = vim.fn.stdpath("data") .. "/lazy/codecompanion.nvim/lua/codecompanion/interactions/chat/ui/init.lua"
  
  if vim.fn.filereadable(ui_file) == 0 then
    return false
  end
  
  -- 读取文件
  local content = table.concat(vim.fn.readfile(ui_file), "\n")
  
  -- 修复 lock_buf 函数
  local lock_pattern = "function UI:lock_buf%(%)"
  local lock_replacement = "function UI:lock_buf()\n  if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then\n    return\n  end"
  
  -- 修复 unlock_buf 函数  
  local unlock_pattern = "function UI:unlock_buf%(%)"
  local unlock_replacement = "function UI:unlock_buf()\n  if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then\n    return\n  end"
  
  content = content:gsub(lock_pattern, lock_replacement)
  content = content:gsub(unlock_pattern, unlock_replacement)
  
  -- 写回文件
  vim.fn.writefile(vim.split(content, "\n"), ui_file)
  return true
end

-- 设置安全的错误处理
function M.setup_safe_handling()
  -- 保存原始函数
  local orig_schedule = vim.schedule
  
  -- 创建安全包装器
  vim.schedule = function(fn)
    return orig_schedule(function()
      local ok, err = pcall(fn)
      if not ok then
        -- 如果是缓冲区错误，静默处理
        if tostring(err):find("Invalid buffer id") then
          return
        end
        -- 其他错误正常抛出
        error(err)
      end
    end)
  end
end

-- 初始化
function M.setup()
  -- 尝试修复源码
  local fixed = M.fix_source_code()
  
  if fixed then
    vim.notify("CodeCompanion 源码修复成功", vim.log.levels.INFO)
  else
    vim.notify("CodeCompanion 源码修复失败，使用运行时保护", vim.log.levels.WARN)
  end
  
  -- 设置安全错误处理
  M.setup_safe_handling()
  
  vim.notify("缓冲区错误保护已启用", vim.log.levels.INFO)
end

return M