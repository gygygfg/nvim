return {
  'nvim-tree/nvim-tree.lua',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'yamatsum/nvim-nonicons',
  },
  config = function()
    -- 先设置 web-devicons
    require('nvim-web-devicons').setup()
    
    -- 然后设置 nonicons
    require('nvim-nonicons').setup()
    
    require("nvim-tree").setup({
      renderer = {
        icons = {
          glyphs = {
            default = "📄",
            symlink = "🔗",
            bookmark = "🔖",
            modified = "●",
            folder = {
              arrow_closed = "▶",
              arrow_open = "▼",
              default = "📁",
              open = "📂",
              empty = "📁",
              empty_open = "📂",
              symlink = "🔗",
              symlink_open = "🔗",
            },
            git = {
              unstaged = "✗",
              staged = "✓",
              unmerged = "⌥",
              renamed = "➜",
              untracked = "★",
              deleted = "✖",
              ignored = "◌",
            },
          },
        },
      },
    })
  end,
  cmd = 'NvimTreeToggle',
  init = require('keymaps').nvim_tree(),
}
