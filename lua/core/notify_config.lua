-- notify_config.lua
-- 解决 Neovim 通知消息历史记录问题
-- 在 VimEnter 之前就捕获所有消息，避免消息丢失
-- 修复重复调用时的缓冲区命名冲突

local M = {}
vim.notify = require('notify')

-- 创建一个全局表来存储所有消息记录
local message_history = {}

-- 保存原始的 vim.notify
local original_notify = vim.notify

-- 包装函数，用于记录所有通知消息
local function wrapped_notify(msg, level, opts)
  -- 记录消息到历史
  if type(msg) == 'string' and msg ~= '' then
    local timestamp = os.date('%H:%M:%S')
    local level_name = ({ 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR' })[level or 3] or 'INFO'

    table.insert(message_history, {
      msg = msg,
      level = level or vim.log.levels.INFO,
      time = timestamp,
      opts = opts or {},
      raw_level = level
    })

    -- 限制历史记录大小
    if #message_history > 100 then
      table.remove(message_history, 1)
    end
  end

  -- 调用原始 notify
  return original_notify(msg, level, opts)
end

-- 在 VimEnter 之前就替换 vim.notify
-- 这会在 Neovim 启动的早期阶段执行
vim.notify = wrapped_notify

-- 设置 VimEnter 自动命令
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    local notify = require('notify')

    -- 设置启动时的临时配置（快速显示）
    notify.setup({
      timeout = 10,
      stages = "static",
      render = "wrapped-compact",
      max_height = function() return 5 end,
      max_width = function() return 80 end,
    })

    -- 延迟切换到正常配置
    vim.defer_fn(function()
      -- 切换到正常配置
      notify.setup({
        timeout = 1500,
        stages = "fade_in_slide_out",
        render = "default",
        max_height = function() return 10 end,
        max_width = function() return 100 end,
        background_colour = "#000000",
        fps = 60,
      })

      -- 重新包装 notify 以使用新配置
      original_notify = notify
      vim.notify = function(msg, level, opts)
        if type(msg) == 'string' and msg ~= '' then
          local timestamp = os.date('%H:%M:%S')
          local level_name = ({ 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR' })[level or 3] or 'INFO'

          table.insert(message_history, {
            msg = msg,
            level = level or vim.log.levels.INFO,
            time = timestamp,
            opts = opts or {},
            raw_level = level
          })

          if #message_history > 100 then
            table.remove(message_history, 1)
          end
        end

        return notify(msg, level, opts)
      end
    end, 2000)
  end,
})

-- 导出功能函数
M.get_history = function()
  return message_history
end

M.clear_history = function()
  message_history = {}
  return true
end

M.show_history = function()
  if #message_history == 0 then
    vim.notify('No notification history', vim.log.levels.INFO)
    return
  end

  -- 生成唯一的缓冲区名称，避免重复调用时的冲突
  local unique_id = tostring(vim.loop.hrtime())
  local buf_name = 'notification-history-' .. unique_id

  -- 创建缓冲区
  local buf = vim.api.nvim_create_buf(false, true)

  -- 设置唯一的缓冲区名称
  vim.api.nvim_buf_set_name(buf, buf_name)

  -- 计算窗口大小和位置
  local max_width = 100
  local max_height = 20

  local lines = {}
  table.insert(lines, "=== Notification History ===")
  table.insert(lines, "")

  for i, item in ipairs(message_history) do
    local level_name = ({ 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR' })[item.level] or 'INFO'
    local prefix = string.format("%3d. [%s] [%s]", i, item.time, level_name)

    -- 处理多行消息
    local msg_lines = vim.split(item.msg, '\n')
    for j, line in ipairs(msg_lines) do
      if j == 1 then
        table.insert(lines, string.format("%s %s", prefix, line))
      else
        table.insert(lines, string.format("      %s", line))
      end
    end

    if i < #message_history then
      table.insert(lines, "")
    end
  end

  -- 计算实际需要的窗口大小
  local content_width = 0
  for _, line in ipairs(lines) do
    content_width = math.max(content_width, #line)
  end

  local win_width = math.min(content_width + 2, max_width, vim.o.columns - 4)
  local win_height = math.min(#lines + 2, max_height, vim.o.lines - 4)
  local row = math.floor((vim.o.lines - win_height) / 2)
  local col = math.floor((vim.o.columns - win_width) / 2)

  -- 创建浮动窗口
  local opts = {
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  }

  local win = vim.api.nvim_open_win(buf, true, opts)

  -- 设置缓冲区内容
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'readonly', true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

  -- 自动滚动到最下面
  vim.api.nvim_win_set_cursor(win, { #lines, 0 })

  -- 设置高亮
  vim.api.nvim_buf_add_highlight(buf, -1, 'Title', 0, 0, -1)

  -- 添加退出快捷键
  local function close_window()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>lua require("core.notify_config")._close_current_window()<CR>',
    { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<ESC>', '<cmd>lua require("core.notify_config")._close_current_window()<CR>',
    { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '<cmd>lua require("core.notify_config")._close_current_window()<CR>',
    { noremap = true, silent = true })

  -- 保存窗口和缓冲区引用
  M._current_window = win
  M._current_buffer = buf

  -- 设置窗口关闭时的自动命令
  vim.api.nvim_create_autocmd({ 'BufWipeout', 'BufHidden', 'BufDelete' }, {
    buffer = buf,
    once = true,
    callback = function()
      M._current_window = nil
      M._current_buffer = nil
    end
  })

  -- 返回窗口和缓冲区引用
  return win, buf
end

-- 关闭当前窗口的函数
M._close_current_window = function()
  if M._current_window and vim.api.nvim_win_is_valid(M._current_window) then
    vim.api.nvim_win_close(M._current_window, true)
  end
  if M._current_buffer and vim.api.nvim_buf_is_valid(M._current_buffer) then
    vim.api.nvim_buf_delete(M._current_buffer, { force = true })
  end
  M._current_window = nil
  M._current_buffer = nil
end

-- 创建用户命令
vim.api.nvim_create_user_command('NotifiCations', function()
  -- 如果已有窗口打开，先关闭它
  if M._current_window and vim.api.nvim_win_is_valid(M._current_window) then
    M._close_current_window()
    vim.defer_fn(function()
      M.show_history()
    end, 50)
  else
    M.show_history()
  end
end, { desc = '查看历史消息' })

vim.api.nvim_create_user_command('NotifiCationsClear', function()
  M.clear_history()
  vim.notify('Notification history cleared', vim.log.levels.INFO)
end, { desc = '清除历史消息' })

vim.api.nvim_create_user_command('NotifiCationsCount', function()
  local count = #message_history
  vim.notify(string.format('Notification history: %d messages', count), vim.log.levels.INFO)
end, { desc = '查看历史消息数量' })

return M
