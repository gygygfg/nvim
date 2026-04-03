-- UI 增强插件配置

vim.pack.add({
  -- nvim-tree.lua - 文件树
  { src = "https://github.com/nvim-tree/nvim-tree.lua" },
  -- bufferline.nvim - 缓冲区标签栏
  { src = "https://github.com/akinsho/bufferline.nvim" },
  -- lualine.nvim - 状态栏
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
})

vim.api.nvim_create_autocmd({'BufRead', 'BufNewFile'}, {
  pattern = '*',
  once = true,
  callback = function()
    require("nvim-tree").setup({
      -- 配置 nvim-tree
      view = {
        width = 30,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = true,
      },
    })

    require("bufferline").setup({
      -- 配置 bufferline
      options = {
        mode = "tabs",
        separator_style = "slant",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    })

    require("lualine").setup({
      -- 配置 lualine
      options = {
        theme = "tokyonight",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    })
  end
})
