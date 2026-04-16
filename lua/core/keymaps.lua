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
_set_keymap("n", "<C-s>", ":w<CR>", { desc = "保存文件" })
_set_keymap("i", "<C-s>", "<Esc>:w<CR>a", { desc = "保存文件" })

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
_set_keymap("n", "<leader>ff", "<cmd>TelescopeFind<CR>", { desc = "查找文件" })
_set_keymap("n", "<leader>fg", function()
  require("plugins.telescope").setup()
  require("telescope.builtin").live_grep()
end, { desc = "搜索文本" })
_set_keymap("n", "<leader>t", ":terminal<CR>a")



local M = {}

function M.codecompanion()
  -- codeCompanion
  local keymap = {}
  function keymap.setup()
    _set_keymap({ "v", "n" }, "<leader>cc", ":CodeCompanionChat<CR>", { desc = "打开 CodeCompanionChat" })
    _set_keymap("v", "<leader>cp", ":CodeCompanionActions<CR>", { desc = "选区调用 CodeCompanion 动作" })
  end

  function keymap.chat()
    return {
      send = {
        description = "发送",
        callback = "keymaps.send",
        modes = { n = "<CR>", i = "<C-s>" },
        opts = {},
      },
      close = {
        description = "关闭聊天",
        callback = "keymaps.close",
        modes = { n = "<C-c>", i = "<C-c>" },
        opts = {},
      },
      stop = {
        description = "停止生成",
        callback = "keymaps.stop",
        modes = { n = "<C-c>" },
        opts = {},
      },
      regenerate = {
        description = "重新生成响应",
        callback = "keymaps.regenerate",
        modes = { n = "gr" },
        opts = {},
      },
      clear = {
        description = "清空聊天",
        callback = "keymaps.clear",
        modes = { n = "gx" },
        opts = {},
      },
      codeblock = {
        description = "复制代码块",
        callback = "keymaps.codeblock",
        modes = { n = "gc" },
        opts = {},
      },
      yank_code = {
        description = "复制代码",
        callback = "keymaps.yank_code",
        modes = { n = "gy" },
        opts = {},
      },
      buffer_sync_all = {
        description = "同步所有缓冲区",
        callback = "keymaps.buffer_sync_all",
        modes = { n = "gba" },
        opts = {},
      },
      buffer_sync_diff = {
        description = "同步差异缓冲区",
        callback = "keymaps.buffer_sync_diff",
        modes = { n = "gbd" },
        opts = {},
      },
      next_chat = {
        description = "下一个聊天",
        callback = "keymaps.next_chat",
        modes = { n = "}" },
        opts = {},
      },
      previous_chat = {
        description = "上一个聊天",
        callback = "keymaps.previous_chat",
        modes = { n = "{" },
        opts = {},
      },
      next_header = {
        description = "下一个标题",
        callback = "keymaps.next_header",
        modes = { n = "]]" },
        opts = {},
      },
      previous_header = {
        description = "上一个标题",
        callback = "keymaps.previous_header",
        modes = { n = "[[" },
        opts = {},
      },
      change_adapter = {
        description = "切换适配器",
        callback = "keymaps.change_adapter",
        modes = { n = "ga" },
        opts = {},
      },
      fold_code = {
        description = "折叠代码",
        callback = "keymaps.fold_code",
        modes = { n = "gf" },
        opts = {},
      },
      debug = {
        description = "debug",
        callback = "keymaps.debug",
        modes = { n = "gd" },
        opts = {},
      },
      system_prompt = {
        description = "切换系统提示",
        callback = "keymaps.toggle_system_prompt",
        modes = { n = "gs" },
        opts = {},
      },
      rules = {
        description = "清除规则",
        callback = "keymaps.clear_rules",
        modes = { n = "gM" },
        opts = {},
      },
      clear_approvals = {
        description = "清除批准",
        callback = "keymaps.clear_approvals",
        modes = { n = "gtx" },
        opts = {},
      },
      yolo_mode = {
        description = "YOLO模式",
        callback = "keymaps.yolo_mode",
        modes = { n = "gty" },
        opts = {},
      },
      goto_file_under_cursor = {
        description = "跳转到光标下文件",
        callback = "keymaps.goto_file_under_cursor",
        modes = { n = "gR" },
        opts = {},
      },
      copilot_stats = {
        description = "Copilot统计",
        callback = "keymaps.copilot_stats",
        modes = { n = "gS" },
        opts = {},
      },
    }
  end

  function keymap.inline()
    return {
      stop = {
        callback = "keymaps.stop",
        description = "停止请求",
        modes = { n = "<C-c>" },
      },
    }
  end

  function keymap.diffy()
    return {
      always_accept = {
        desc = "总是同意",
        callback = "keymaps.always_accept",
        modes = { n = "a" },
      },
      accept_change = {
        description = "本次同意",
        callback = "keymaps.accept_change",
        modes = { n = "y" },
      },
      reject_change = {
        description = "取消一次",
        callback = "keymaps.reject_change",
        modes = { n = "n" },
      },
      next_hunk = {
        description = "下一个差异块",
        callback = "keymaps.next_hunk",
        modes = { n = "}" },
      },
      previous_hunk = {
        description = "上一个差异块",
        callback = "keymaps.previous_hunk",
        modes = { n = "{" },
      },
    }
  end

  return keymap
end

return M
