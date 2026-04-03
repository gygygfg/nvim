-- lua/config/lualine.lua
-- Lualine 状态栏配置，启动时加载

vim.pack.add({
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
})

vim.api.nvim_create_autocmd('VimEnter', {
-- 在 VimEnter 事件中加载 lualine
  pattern = '*',
  once = true,
  callback = function()
    -- 检查插件是否已加载
    if not package.loaded['lualine'] then
      require('lualine').setup({
        -- 设置配置
        options = {
          icons_enabled = true,
          theme = 'tokyonight',
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {},
      })
    end
  end,
})
