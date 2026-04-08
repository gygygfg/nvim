-- lua/core/keymaps.lua
-- 核心按键映射配置

local function _set_keymap(mode, lhs, rhs, opts)
  opts = opts or { noremap = true, silent = true }
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- 设置 leader 键
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 常用操作
_set_keymap('n', '<C-s>', ':w<CR>', { desc = '保存文件' })
_set_keymap('i', '<C-s>', '<Esc>:w<CR>a', { desc = '保存文件' })

-- 取消高亮
_set_keymap("n", "<leader>h", ":nohl<CR>", { desc = "取消搜索高亮" })

-- 窗口管理
_set_keymap("n", "<C-h>", "<C-w>h", { desc = "切换到左窗口" })
_set_keymap("n", "<C-j>", "<C-w>j", { desc = "切换到下窗口" })
_set_keymap("n", "<C-k>", "<C-w>k", { desc = "切换到上窗口" })
_set_keymap("n", "<C-l>", "<C-w>l", { desc = "切换到右窗口" })

-- 缓冲区管理
_set_keymap("n", "<leader>bn", ":bnext<CR>", { desc = "下一个缓冲区" })
_set_keymap("n", "<leader>bp", ":bprevious<CR>", { desc = "上一个缓冲区" })
_set_keymap("n", "<leader>bd", ":bdelete<CR>", { desc = "关闭缓冲区" })

-- Git 快捷键
_set_keymap("n", "<leader>gs", "<cmd>Gstatus<CR>", { desc = "Git 状态" })
_set_keymap("n", "<leader>gd", "<cmd>Gdiff<CR>", { desc = "Git 差异" })
_set_keymap("n", "<leader>gb", "<cmd>Gblame<CR>", { desc = "Git 追溯" })
_set_keymap("n", "<leader>gp", "<cmd>Git push<CR>", { desc = "Git 推送" })
_set_keymap("n", "<leader>gl", "<cmd>Git pull<CR>", { desc = "Git 拉取" })
_set_keymap('n', '<leader>ff', '<cmd>TelescopeFind<CR>', { desc = '查找文件' })
_set_keymap('n', '<leader>fg', function()
  require('plugins.telescope').setup()
  require('telescope.builtin').live_grep()
end, { desc = '搜索文本' })
_set_keymap('n', '<leader>t', ':terminal<CR>a')

local M = {}

-- 导入 git commit 模块
local git_commit = require("plugins.git.commit")
local function _set_keymap(mode, lhs, rhs, opts)
  opts = opts or { noremap = true, silent = true }
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.codecompanion()
  -- codeCompanion
  local keymap = {}
  function keymap.setup()
    _set_keymap({ "v", "n" }, "<leader>cc", ":CodeCompanionChat<CR>", { desc = "打开 CodeCompanionChat" })
    _set_keymap("v", "<leader>cp", ":CodeCompanionActions<CR>", { desc = "选区调用 CodeCompanion 动作" })
  end

  function keymap.chat()
    return {
      options = {
        description = "选项",
        modes = { n = "?" },
        callback = "keymaps.options",
        hide = true,
      },
      completion = {
        description = "[聊天] 补全菜单",
        modes = { i = "<C->_>" },
        index = 1,
        callback = "keymaps.completion",
      },
      send = {
        description = "[请求] 发送响应",
        modes = {
          n = { "<CR>", "<C-s>" },
          i = "<C-s>",
        },
        index = 2,
        callback = "keymaps.send",
      },
      regenerate = {
        description = "[请求] 重新生成",
        modes = { n = "gr" },
        index = 3,
        callback = "keymaps.regenerate",
      },
      close = {
        description = "[聊天] 关闭",
        modes = {
          n = "<C-d>",
          i = "<C-d>",
        },
        index = 4,
        callback = "keymaps.close",
      },
      stop = {
        description = "[请求] 停止",
        modes = { n = "<C-c>" },
        index = 5,
        callback = "keymaps.stop",
      },
      clear = {
        description = "[聊天] 清空",
        modes = { n = "gx" },
        index = 6,
        callback = "keymaps.clear",
      },
      codeblock = {
        description = "[聊天] 插入代码块",
        modes = { n = "gc" },
        index = 7,
        callback = "keymaps.codeblock",
      },
      yank_code = {
        description = "[聊天] 复制代码",
        modes = { n = "gy" },
        index = 8,
        callback = "keymaps.yank_code",
      },
      buffer_sync_all = {
        description = "[聊天] 切换缓冲区同步",
        modes = { n = "gba" },
        index = 9,
        callback = "keymaps.buffer_sync_all",
      },
      buffer_sync_diff = {
        description = "[聊天] 切换缓冲区差异同步",
        modes = { n = "gbd" },
        index = 10,
        callback = "keymaps.buffer_sync_diff",
      },
      next_chat = {
        description = "[导航] 下一个聊天",
        modes = { n = "}" },
        index = 11,
        callback = "keymaps.next_chat",
      },
      previous_chat = {
        description = "[导航] 上一个聊天",
        modes = { n = "{" },
        index = 12,
        callback = "keymaps.previous_chat",
      },
      next_header = {
        description = "[导航] 下一个标题",
        modes = { n = "]]" },
        index = 13,
        callback = "keymaps.next_header",
      },
      previous_header = {
        description = "[导航] 上一个标题",
        modes = { n = "[[" },
        index = 14,
        callback = "keymaps.previous_header",
      },
      change_adapter = {
        description = "[适配器] 更改适配器和模型",
        modes = { n = "ga" },
        index = 15,
        callback = "keymaps.change_adapter",
      },
      fold_code = {
        description = "[聊天] 折叠代码",
        modes = { n = "gf" },
        index = 15,
        callback = "keymaps.fold_code",
      },
      debug = {
        description = "[聊天] 查看调试信息",
        modes = { n = "gd" },
        index = 16,
        callback = "keymaps.debug",
      },
      system_prompt = {
        description = "[聊天] 切换系统提示",
        modes = { n = "gs" },
        index = 17,
        callback = "keymaps.toggle_system_prompt",
      },
      rules = {
        description = "[聊天] 清除规则",
        modes = { n = "gM" },
        index = 18,
        callback = "keymaps.clear_rules",
      },
      clear_approvals = {
        description = "[Tools] Clear approvals",
        modes = { n = "gtx" },
        index = 19,
        callback = "keymaps.clear_approvals",
      },
      yolo_mode = {
        description = "[Tools] Toggle YOLO mode",
        modes = { n = "gty" },
        index = 20,
        callback = "keymaps.yolo_mode",
      },
      goto_file_under_cursor = {
        description = "[Chat] Open file under cursor",
        modes = { n = "gR" },
        index = 21,
        callback = "keymaps.goto_file_under_cursor",
      },
      copilot_stats = {
        description = "[Adapter] Copilot statistics",
        modes = { n = "gS" },
        index = 22,
        callback = "keymaps.copilot_stats",
      },
      super_diff = {
        description = "[Tools] Show Super Diff",
        modes = { n = "gD" },
        index = 23,
        callback = "keymaps.super_diff",
      },
      -- Keymaps for ACP permission requests
      _acp_allow_always = {
        description = "Allow Always",
        modes = { n = "g1" },
        callback = function() end,
      },
      _acp_allow_once = {
        description = "Allow Once",
        modes = { n = "g2" },
        callback = function() end,
      },
      _acp_reject_once = {
        description = "Reject Once",
        modes = { n = "g3" },
        callback = function() end,
      },
      _acp_reject_always = {
        description = "Reject Always",
        modes = { n = "g4" },
        callback = function() end,
      },
    }
  end

  function keymap.inline()
    return {
      always_accept = {
        callback = "keymaps.always_accept",
        description = "允许全部",
        index = 1,
        modes = { n = "a" },
        opts = { nowait = true },
      },
      accept_change = {
        callback = "keymaps.accept_change",
        description = "允许一次",
        index = 2,
        modes = { n = "y" },
        opts = { nowait = true, noremap = true },
      },
      reject_change = {
        callback = "keymaps.reject_change",
        description = "拒绝更改",
        index = 3,
        modes = { n = "r" },
        opts = { nowait = true, noremap = true },
      },
      stop = {
        description = "停止",
        callback = "keymaps.stop",
        index = 4,
        modes = { n = "q" },
      },
    }
  end

  return keymap
end

return M
