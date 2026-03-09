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
    
    -- 加载 nvim-tree 扩展（注意拼写：extensions 不是 extentions）
    local nonicons_extension = require("nvim-nonicons.extensions.nvim-tree")
    
    require("nvim-tree").setup({
      renderer = {
        icons = {
          glyphs = nonicons_extension.glyphs,
        },
      },
    })
  end,
  cmd = 'NvimTreeToggle',
  init = require('keymaps').nvim_tree(),
}
