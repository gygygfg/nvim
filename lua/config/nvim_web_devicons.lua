-- lua/config/nvim_web_devicons.lua
-- 文件图标插件配置，启动时加载

vim.pack.add({
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
})

vim.api.nvim_create_autocmd('VimEnter', {
-- 在 VimEnter 事件中加载 nvim-web-devicons
  pattern = '*',
  once = true,
  callback = function()
    -- 检查插件是否已加载
    if not package.loaded['nvim-web-devicons'] then
      -- 加载插件
      vim.cmd('packadd nvim-web-devicons')
      
      -- 设置配置
      require('nvim-web-devicons').setup()
    end
  end,
})
