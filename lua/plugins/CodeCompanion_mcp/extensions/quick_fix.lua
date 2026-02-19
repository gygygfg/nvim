-- CodeCompanion 快速修复模块
-- 直接修复缓冲区错误问题

local M = {}

-- 直接修改插件文件
function M.apply_direct_fix()
  -- 插件文件路径
  local plugin_path = vim.fn.stdpath("data") .. "/lazy/codecompanion.nvim"
  local ui_file = plugin_path .. "/lua/codecompanion/interactions/chat/ui/init.lua"
  
  -- 检查文件是否存在
  if vim.fn.filereadable(ui_file) == 0 then
    vim.notify("UI 文件不存在: " .. ui_file, vim.log.levels.WARN)
    return false
  end
  
  -- 读取文件内容
  local lines = {}
  for line in io.lines(ui_file) do
    table.insert(lines, line)
  end
  
  local modified = false
  
  -- 查找并修复 lock_buf 函数
  for i = 1, #lines do
    if lines[i]:match("^function UI:lock_buf%(%)") then
      -- 在函数开始处添加缓冲区检查
      table.insert(lines, i + 1, "  -- Check if buffer is still valid")
      table.insert(lines, i + 2, "  if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then")
      table.insert(lines, i + 3, "    return")
      table.insert(lines, i + 4, "  end")
      modified = true
      break
    end
  end
  
  -- 查找并修复 unlock_buf 函数
  for i = 1, #lines do
    if lines[i]:match("^function UI:unlock_buf%(%)") then
      -- 在函数开始处添加缓冲区检查
      table.insert(lines, i + 1, "  -- Check if buffer is still valid")
      table.insert(lines, i + 2, "  if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then")
      table.insert(lines, i + 3, "    return")
      table.insert(lines, i + 4, "  end")
      modified = true
      break
    end
  end
  
  -- 如果修改了，写回文件
  if modified then
    local file = io.open(ui_file, "w")
    if file then
      for _, line in ipairs(lines) do
        file:write(line .. "\n")
      end
      file:close()
      vim.notify("CodeCompanion 缓冲区修复已直接应用", vim.log.levels.INFO)
      return true
    else
      vim.notify("无法写入文件: " .. ui_file, vim.log.levels.ERROR)
      return false
    end
  else
    vim.notify("未找到需要修复的函数", vim.log.levels.WARN)
    return false
  end
end

-- 运行时修复
function M.apply_runtime_fix()
  -- 等待插件加载
  vim.defer_fn(function()
    -- 尝试获取 UI 模块
    local ok, ui = pcall(require, "codecompanion.interactions.chat.ui")
    if not ok then
      vim.notify("UI 模块未加载，稍后重试", vim.log.levels.DEBUG)
      vim.defer_fn(M.apply_runtime_fix, 1000)
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
    
    -- 修复 lock_buf
    local original_lock = mt.__index.lock_buf
    if original_lock then
      mt.__index.lock_buf = function(self)
        if vim.api.nvim_buf_is_valid(self.chat_bufnr) then
          return original_lock(self)
        end
      end
    end
    
    -- 修复 unlock_buf
    local original_unlock = mt.__index.unlock_buf
    if original_unlock then
      mt.__index.unlock_buf = function(self)
        if vim.api.nvim_buf_is_valid(self.chat_bufnr) then
          return original_unlock(self)
        end
      end
    end
    
    vim.notify("CodeCompanion 运行时修复已应用", vim.log.levels.INFO)
  end, 2000)
end

-- 设置错误处理
function M.setup_error_handling()
  -- 保存原始函数
  local original_schedule = vim.schedule
  
  -- 包装 vim.schedule
  vim.schedule = function(fn)
    return original_schedule(function()
      local ok, err = pcall(fn)
      if not ok and not string.find(tostring(err), "Invalid buffer id") then
        error(err)
      end
    end)
  end
end

-- 初始化
function M.setup()
  -- 尝试直接修复
  local fixed = M.apply_direct_fix()
  
  if not fixed then
    -- 如果直接修复失败，使用运行时修复
    M.apply_runtime_fix()
  end
  
  -- 设置错误处理
  M.setup_error_handling()
  
  vim.notify("CodeCompanion 快速修复模块已启用", vim.log.levels.INFO)
end

return M