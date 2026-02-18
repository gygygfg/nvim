local M = {
  'nvim-tree/nvim-web-devicons',
  config = function()
    require 'nvim-web-devicons'.setup {
      override = {
        zsh = {
          icon = "",
          color = "#428850",
          cterm_color = "65",
          name = "Zsh"
        },
        py = {
          icon = "",
          color = "#3572A5",
          cterm_color = "67",
          name = "Python"
        }
      },
      color_icons = false,
      default = true,
      strict = true,
    }
  end,
}
return M

-- 文件编辑测试完成于 2026-02-16
-- 此文件用于演示 insert_edit_into_file 工具的使用
