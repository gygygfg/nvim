-- lua/config/nvim_tree.lua
-- Nvim-tree 文件树配置，按键触发加载

vim.pack.add({
  { src = "https://github.com/nvim-tree/nvim-tree.lua" },
})

local function load_nvim_tree()
-- 定义 Nvim-tree 快捷键，按键时加载插件
  -- 检查插件是否已加载
  if not package.loaded['nvim-tree'] then
    -- 加载插件
    vim.cmd('packadd nvim-tree.lua')
    
    -- 设置配置
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
  
  return require('nvim-tree.api')
end

vim.keymap.set('n', '<leader>e', function()
-- 设置快捷键，按键时加载 Nvim-tree
  local api = load_nvim_tree()
  api.tree.toggle()
end, { desc = '切换文件树' })
