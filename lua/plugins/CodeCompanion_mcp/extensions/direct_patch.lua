-- CodeCompanion 直接补丁模块
-- 直接修改插件源码来修复缓冲区错误

local M = {}

-- 直接修改 UI 模块的源码
function M.patch_ui_module()
  -- UI 模块的路径
  local ui_path = vim.fn.stdpath("data") .. "/lazy/codecompanion.nvim/lua/codecompanion/interactions/chat/ui/init.lua"
  
  -- 检查文件是否存在
  if vim.fn.filereadable(ui_path) == 0 then
    vim.notify("UI 模块文件不存在: " .. ui_path, vim.log.levels.WARN)
    return false
  end

  -- 读取文件内容
  local lines = {}
  for line in io.lines(ui_path) do
    table.insert(lines, line)
  end

  -- 查找需要修改的函数
  local modified = false
  
  for i, line in ipairs(lines) do
    -- 查找 lock_buf 函数
    if line:match("^function UI:lock_buf%(%)") then
      -- 在函数开始处添加缓冲区检查
      table.insert(lines, i + 1, "  -- Check if buffer is still valid before accessing it")
      table.insert(lines, i + 2, "  if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then")
      table.insert(lines, i + 3, "    return")
      table.insert(lines, i + 4, "  end")
      modified = true
      break
    end
  end
  
  for i, line in ipairs(lines) do
    -- 查找 unlock_buf 函数
    if line:match("^function UI:unlock_buf%(%)") then
      -- 在函数开始处添加缓冲区检查
      table.insert(lines, i + 1, "  -- Check if buffer is still valid before accessing it")
      table.insert(lines, i + 2, "  if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then")
      table.insert(lines, i + 3, "    return")
      table.insert(lines, i + 4, "  end")
      modified = true
      break
    end
  end

  -- 如果修改了，写回文件
  if modified then
    local file = io.open(ui_path, "w")
    if file then
      for _, line in ipairs(lines) do
        file:write(line .. "\n")
      end
      file:close()
      vim.notify("已成功修补 UI 模块", vim.log.levels.INFO)
      return true
    else
      vim.notify("无法写入 UI 模块文件", vim.log.levels.ERROR)
      return false
    end
  else
    vim.notify("未找到需要修补的函数", vim.log.levels.WARN)
    return false
  end
end

-- 运行时猴子补丁
function M.runtime_monkey_patch()
  -- 等待 CodeCompanion 加载
  vim.defer_fn(function()
    -- 尝试获取 UI 模块
    local ok, ui = pcall(require, "codecompanion.interactions.chat.ui")
    if not ok then
      vim.notify("无法加载 UI 模块进行运行时补丁", vim.log.levels.WARN)
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

    -- 修补 lock_buf
    local original_lock_buf = mt.__index.lock_buf
    if original_lock_buf then
      mt.__index.lock_buf = function(self)
        if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then
          return
        end
        return original_lock_buf(self)
      end
    end

    -- 修补 unlock_buf
    local original_unlock_buf = mt.__index.unlock_buf
    if original_unlock_buf then
      mt.__index.unlock_buf = function(self)
        if not vim.api.nvim_buf_is_valid(self.chat_bufnr) then
          return
        end
        return original_unlock_buf(self)
      end
    end

    vim.notify("运行时猴子补丁已应用", vim.log.levels.INFO)
  end, 2000) -- 2秒后执行
end

-- 设置错误处理器
function M.setup_error_handling()
  -- 包装关键函数以防止错误传播
  local key_functions = {
    "vim.schedule",
    "vim.schedule_wrap",
    "vim.defer_fn",
  }

  for _, func_name in ipairs(key_functions) do
    local parts = vim.split(func_name, ".")
    local obj = vim
    for i = 1, #parts - 1 do
      obj = obj[parts[i]]
    end
    local original = obj[parts[#parts]]
    
    if original then
      obj[parts[#parts]] = function(fn)
        return original(function(...)
          local ok, err = pcall(fn, ...)
          if not ok then
            -- 检查是否是缓冲区错误
            if string.find(tostring(err), "Invalid buffer id") then
              -- 静默处理
              return
            end
            -- 重新抛出其他错误
            error(err)
          end
        end)
      end
    end
  end
end

-- 初始化
function M.setup()
  -- 尝试直接修补源码
  local patched = M.patch_ui_module()
  
  if not patched then
    -- 如果直接修补失败，使用运行时补丁
    M.runtime_monkey_patch()
  end
  
  -- 设置错误处理
  M.setup_error_handling()
  
  vim.notify("CodeCompanion 缓冲区错误修复已启用", vim.log.levels.INFO)
end

return M