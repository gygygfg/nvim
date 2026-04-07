-- vim-fugitive 配置模块
local M = {}

function M.setup()
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
end

return M
