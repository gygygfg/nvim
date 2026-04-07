-- lua/config/nvim_tree.lua
-- Nvim-tree 文件树配置

local M = {}

function M.toggle()
  require('nvim-tree.api').tree.toggle()
end

function M.setup()
  require('nvim-tree').setup({
    sort_by = 'case_sensitive',
    view = {
      width = 30,
      side = 'left',
    },
    renderer = {
      group_empty = true,
      icons = {
        show = {
          file = true,
          folder = true,
          folder_arrow = true,
          git = true,
        },
        glyphs = {
          default = '',
          symlink = '',
          folder = {
            default = '',
            open = '',
            empty = '',
            empty_open = '',
            symlink = '',
            symlink_open = '',
          },
          git = {
            unstaged = '',
            staged = 'S',
            unmerged = '',
            renamed = '➜',
            untracked = 'U',
            deleted = '',
            ignored = '◌',
          },
        },
      },
    },
    filters = {
      dotfiles = false,
    },
  })
end

vim.keymap.set('n', '<leader>e', function()
  M.toggle()
end, { desc = '切换文件树' })

return M
