-- ~/.config/nvim/core/format_guard.lua
-- 统一的格式化守卫：在格式化启动前校验缓冲区是否可以安全格式化。
-- 用于拦截 nomodifiable / 特殊缓冲区，避免异步回调中抛出
-- "Buffer is not 'modifiable'" 或 "Invalid buffer id"。

local M = {}

-- 允许格式化的 buftype（"acwrite" 用于需要 :write 触发的特殊缓冲区）
local ALLOWED_BUFTYPE = {
  [""] = true,
  acwrite = true,
}

---判断给定缓冲区当前是否可以被安全格式化。
---@param bufnr integer|nil 目标缓冲区，默认使用当前缓冲区
---@return boolean
function M.is_formattable(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    return false
  end

  local bo = vim.bo[bufnr]

  -- 不可修改的缓冲区（如只读预览、Telescope 结果等）直接跳过
  if not bo.modifiable then
    return false
  end

  -- 拒绝 terminal / prompt / quickfix / nofile 等特殊缓冲区
  if not ALLOWED_BUFTYPE[bo.buftype] then
    return false
  end

  -- 没有文件类型的缓冲区无需格式化
  if bo.filetype == "" then
    return false
  end

  return true
end

return M
