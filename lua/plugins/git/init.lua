-- Git 相关插件管理配置
-- 这个文件管理所有与 Git 相关的插件
return {
  {
    -- vim-fugitive: Git 集成插件
    "tpope/vim-fugitive",
    lazy = false,  -- 启动时立即加载
    config = function()
      -- 自定义 fugitive 行为
      vim.g.fugitive_summary_format = "%s"  -- 提交信息只显示标题
      vim.g.fugitive_git_executable = "git" -- 指定 git 路径

      -- 自动关闭 fugitive 缓冲区
      vim.api.nvim_create_autocmd("BufWinLeave", {
        pattern = "fugitive://*",
        callback = function()
          if vim.fn.bufname() == "" then
            vim.cmd("silent! checktime")
          end
        end
      })

      -- 自定义 Gstatus 窗口外观
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "fugitive",
        callback = function()
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
          vim.opt_local.signcolumn = "no"
        end
      })
    end,
    init =  require("keymaps").fugitive(),
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
    event = { "BufReadPre", "BufNewFile" },
  },
  {
    "sindrets/diffview.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require("diffview").setup()
    end,
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles" },
  },
  {
    "nvim-telescope/telescope.nvim",
    config = function()
      require("keymaps").telescope()
    end,
    cmd = {"Telescope"},
  },
  -- 加载 git commit 模块
  init = require("plugins.git.commit").setup(),
}
