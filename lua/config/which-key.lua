-- lua/config/which-key.lua
-- Which-key 按键提示配置，启动时加载

vim.pack.add({
  { src = "https://github.com/folke/which-key.nvim" },
})

vim.api.nvim_create_autocmd('VimEnter', {
-- 在 VimEnter 事件中加载 which-key
  pattern = '*',
  once = true,
  callback = function()
    -- 检查插件是否已加载
    if not package.loaded['which-key'] then
      -- 加载插件
      vim.cmd('packadd which-key.nvim')
      
      -- 设置配置
      require('which-key').setup({
        plugins = {
          marks = true,
          registers = true,
          spelling = {
            enabled = true,
            suggestions = 20,
          },
          presets = {
            operators = true,
            motions = true,
            text_objects = true,
            windows = true,
            nav = true,
            z = true,
            g = true,
          },
        },
        window = {
          border = 'single',
          position = 'bottom',
          margin = { 1, 0, 1, 0 },
          padding = { 2, 2, 2, 2 },
          winblend = 0,
        },
        layout = {
          height = { min = 4, max = 25 },
          width = { min = 20, max = 50 },
          spacing = 3,
          align = 'left',
        },
        ignore_missing = true,
        hidden = { '<silent>', '<cmd>', '<Cmd>', '<CR>', 'call', 'lua', '^:', '^ ' },
        show_help = true,
        triggers = 'auto',
        triggers_blacklist = {
          i = { 'j', 'k' },
          v = { 'j', 'k' },
        },
      })
    end
  end,
})
