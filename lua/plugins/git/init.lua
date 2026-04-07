-- Git 相关配置（vim pack 格式）
-- 这个文件管理所有与 Git 相关的配置
-- 插件通过 vim pack 系统加载

-- ============================================
-- Git 插件安装定义
-- ============================================

vim.pack.add({
  -- gitsigns.nvim - Git 状态显示
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
})

vim.pack.add({
  -- diffview.nvim - Git diff 查看
  { src = "https://github.com/sindrets/diffview.nvim" },
})

vim.pack.add({
  -- fugitive.vim - Git 集成
  { src = "https://github.com/tpope/vim-fugitive" },
})

-- ============================================
-- Git 配置加载
-- ============================================

-- 初始化 Git 相关配置
-- 加载 git commit 模块
require("plugins.git.commit").setup()

-- 加载 fugitive 配置模块
require("plugins.git.fugitive").setup()

-- 设置快捷键映射
-- require("core.keymaps").fugitive()
-- require("core.keymaps").telescope()
