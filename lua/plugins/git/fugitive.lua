-- vim-fugitive 配置 - 强制加载版本
return {
  "tpope/vim-fugitive",
  -- 不使用任何懒加载选项
  lazy = false,
  -- 在启动时立即加载
  confing = function()
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
  init = require("keymaps").fugitive()
}
