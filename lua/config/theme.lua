-- 主题插件配置

vim.pack.add({
  -- tokyonight.nvim - 主题插件
  { src = "https://github.com/folke/tokyonight.nvim" },
})
  
  vim.api.nvim_create_autocmd('VimEnter', {
	      callback = function()
  require("tokyonight").setup({
  -- 设置主题配置
    style = "night", -- 主题风格: storm, night, day
    transparent = false, -- 背景透明
    terminal_colors = true, -- 终端颜色
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
      functions = {},
      variables = {},
      sidebars = "dark", -- 侧边栏样式
      floats = "dark", -- 浮动窗口样式
    },
    sidebars = { "qf", "help" }, -- 应用深色样式的侧边栏
    day_brightness = 0.3, -- 白天模式亮度
    hide_inactive_statusline = false, -- 隐藏非活动状态栏
    dim_inactive = false, -- 非活动窗口变暗
    lualine_bold = false, -- Lualine 使用粗体
  })
  
  -- 设置主题
  vim.cmd("colorscheme tokyonight")
  end
  })
