-- 图标插件配置
vim.pack.add({
  -- nvim-web-devicons - 文件图标
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  -- mini.icons - 迷你图标
  { src = "https://github.com/nvim-mini/mini.icons" },
})

vim.api.nvim_create_autocmd('UIEnter', {
  pattern = '*',
  once = true,
  callback = function()
    -- 检查插件是否已加载
    if not package.loaded['mini.icons'] then
      -- 设置配置
      require('mini.icons').setup({
        -- 配置 mini.icons
        -- 默认配置
      })
    end

    require("nvim-web-devicons").setup({
      -- 配置 nvim-web-devicons
      -- 默认配置
      override = {},
      default = true,
    })
  end,
})
