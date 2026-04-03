-- lua/config/tokyonight.lua
-- TokyoNight 主题配置，启动时加载

vim.pack.add({
  { src = "https://github.com/folke/tokyonight.nvim" },
})

-- 检查插件是否已加载
if not package.loaded['tokyonight'] then
  -- 加载主题插件
  vim.cmd('packadd tokyonight')

  -- 设置主题
  vim.cmd('colorscheme tokyonight')
end
