-- lua/core/folding.lua
-- 缩进驱动折叠：折叠层级由「实际缩进 / 缩进宽度」决定（foldmethod=indent）。
-- 缩进宽度取 shiftwidth（为 0 时回退 tabstop），因此折叠层级始终与当前缩进设置一致，
-- 不会出现「缩进改成 2 格、折叠仍按 4 格」的错位。
-- 注意：不使用 treesitter 的语法折叠——其层级与缩进无关，会与缩进设置脱节。

local M = {}

local augroup = vim.api.nvim_create_augroup("CoreIndentFold", { clear = true })

-- 不强制缩进折叠的 buffer：插件自带折叠 / 特殊视图（NeoAI 浮窗、文件树、quickfix 等）。
local EXCLUDE = {
  help = true,
  qf = true,
  nvimtree = true,
  NvimTree = true,
  lazy = true,
  mason = true,
  notify = true,
  noice = true,
  oil = true,
  fugitive = true,
  TelescopePrompt = true,
  ["dap-repl"] = true,
  dapui_scopes = true,
  dapui_breakpoints = true,
  dapui_stacks = true,
  dapui_watches = true,
  dapui_console = true,
  packer = true,
}

--- 是否为不强制缩进折叠的 buffer
--- @param buf number
--- @return boolean
local function _excluded(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return true end
  if vim.bo[buf].buftype ~= "" then return true end -- terminal / quickfix / nofile / prompt
  local ft = vim.bo[buf].filetype
  if ft == "" then return false end
  if ft:sub(1, 5) == "neoai" then return true end -- NeoAI 自带折叠的浮窗
  return EXCLUDE[ft] == true
end

--- 对普通代码 buffer 的窗口应用缩进折叠（foldmethod/foldlevel 为窗口局部选项）。
--- 仅在当前不是 indent 折叠时设置，避免每次进入窗口都重置 foldlevel、把用户展开的折叠收起。
--- @param buf number
local function _apply(buf)
  if _excluded(buf) then return end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) then
      if vim.api.nvim_get_option_value("foldmethod", { win = win }) ~= "indent" then
        vim.api.nvim_set_option_value("foldmethod", "indent", { win = win })
        vim.api.nvim_set_option_value("foldenable", true, { win = win })
        vim.api.nvim_set_option_value("foldlevel", 99, { win = win }) -- 默认展开所有折叠
      end
    end
  end
end

local _pending = false
--- 合并同一 tick 内的多次选项变更，重算当前窗口折叠（indent 折叠按 shiftwidth 计算）。
local function _refresh()
  if _pending then return end
  _pending = true
  vim.schedule(function()
    _pending = false
    if vim.wo.foldmethod ~= "indent" then return end
    pcall(vim.cmd, "silent! normal! zx")
  end)
end

--- 安装缩进折叠：文件类型/窗口进入时应用，缩进选项变化时自动重算。
function M.setup()
  vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    group = augroup,
    callback = function(args) _apply(args.buf) end,
  })
  -- shiftwidth/tabstop 等变化会改变 indent 折叠层级：即时重算，保证与缩进匹配。
  vim.api.nvim_create_autocmd("OptionSet", {
    group = augroup,
    pattern = { "shiftwidth", "tabstop", "softtabstop", "expandtab" },
    callback = _refresh,
  })
end

return M
