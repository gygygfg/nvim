-- lua/config/noice.lua
-- Noice 通知系统配置，启动后加载

vim.pack.add({
  { src = "https://github.com/folke/noice.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  { src = "https://github.com/rcarriga/nvim-notify" },
})

vim.api.nvim_create_autocmd('VimEnter', {
-- 在 VimEnter 事件中加载 noice 及其依赖
  pattern = '*',
  once = true,
  callback = function()
    -- 先加载依赖插件
    if not package.loaded['nui'] then
      vim.cmd('packadd nui')
    end
    
    if not package.loaded['nvim-notify'] then
      vim.cmd('packadd nvim-notify')
    end
    
    -- 加载 noice 插件
    if not package.loaded['noice'] then
      vim.cmd('packadd noice')
      
      -- 设置配置
      require('noice').setup({
        views = {
          notify = {
            position = { row = 1, col = -1 } -- 顶部右侧显示通知
          }
        }
      })
    end
  end,
})
