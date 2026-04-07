-- lua/core/keymaps.lua
-- 核心按键映射配置

local M = {}

local function _set_keymap(mode, lhs, rhs, opts)
  opts = opts or { noremap = true, silent = true }
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.setup()
  -- 设置 leader 键
  vim.g.mapleader = " "
  vim.g.maplocalleader = "\\"

  -- ============================================================
  -- 常用操作
  -- ============================================================
  _set_keymap('n', '<C-s>', ':w<CR>', { desc = '保存文件' })
  _set_keymap('i', '<C-s>', '<Esc>:w<CR>a', { desc = '保存文件' })

  -- 取消高亮
  _set_keymap("n", "<leader>h", ":nohl<CR>", { desc = "取消搜索高亮" })

  -- ============================================================
  -- 窗口管理
  -- ============================================================
  _set_keymap("n", "<C-h>", "<C-w>h", { desc = "切换到左窗口" })
  _set_keymap("n", "<C-j>", "<C-w>j", { desc = "切换到下窗口" })
  _set_keymap("n", "<C-k>", "<C-w>k", { desc = "切换到上窗口" })
  _set_keymap("n", "<C-l>", "<C-w>l", { desc = "切换到右窗口" })

  -- ============================================================
  -- 缓冲区管理
  -- ============================================================
  _set_keymap("n", "<leader>bn", ":bnext<CR>", { desc = "下一个缓冲区" })
  _set_keymap("n", "<leader>bp", ":bprevious<CR>", { desc = "上一个缓冲区" })
  _set_keymap("n", "<leader>bd", ":bdelete<CR>", { desc = "关闭缓冲区" })

  -- ============================================================
  -- Git 快捷键
  -- ============================================================
  _set_keymap("n", "<leader>gs", "<cmd>Gstatus<CR>", { desc = "Git 状态" })
  _set_keymap("n", "<leader>gd", "<cmd>Gdiff<CR>", { desc = "Git 差异" })
  _set_keymap("n", "<leader>gb", "<cmd>Gblame<CR>", { desc = "Git 追溯" })
  _set_keymap("n", "<leader>gp", "<cmd>Git push<CR>", { desc = "Git 推送" })
  _set_keymap("n", "<leader>gl", "<cmd>Git pull<CR>", { desc = "Git 拉取" })
end

return M
