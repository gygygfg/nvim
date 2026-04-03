-- lua/config/bufferline.lua
-- Bufferline 缓冲区标签栏配置，启动时加载

vim.pack.add({
  { src = "https://github.com/akinsho/bufferline.nvim" },
})

vim.api.nvim_create_autocmd('VimEnter', {
  -- 在 VimEnter 事件中加载 bufferline
  pattern = '*',
  once = true,
  callback = function()
    -- 检查插件是否已加载
    if not package.loaded['bufferline'] then
      -- 加载插件
      vim.cmd('packadd bufferline.nvim')

      -- 设置配置
      require('bufferline').setup({
        options = {
          mode = 'buffers',
          style_preset = 'default',
          themable = true,
          numbers = 'none',
          close_command = 'bdelete! %d',
          right_mouse_command = 'bdelete! %d',
          left_mouse_command = 'buffer %d',
          middle_mouse_command = nil,
          indicator = {
            style = 'icon',
          },
          buffer_close_icon = '󰅖',
          modified_icon = '●',
          close_icon = '',
          left_trunc_marker = '',
          right_trunc_marker = '',
          max_name_length = 18,
          max_prefix_length = 15,
          tab_size = 18,
          diagnostics = 'nvim_lsp',
          diagnostics_update_in_insert = false,
          offsets = {
            {
              filetype = 'NvimTree',
              text = '文件树',
              text_align = 'center',
              separator = true,
            },
          },
          color_icons = true,
          show_buffer_icons = true,
          show_buffer_close_icons = true,
          show_close_icon = true,
          show_tab_indicators = true,
          persist_buffer_sort = true,
          separator_style = 'thin',
          enforce_regular_tabs = false,
          always_show_bufferline = true,
        },
      })
    end
  end,
})
