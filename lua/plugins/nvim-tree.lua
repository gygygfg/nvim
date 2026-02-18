return {
  'nvim-tree/nvim-tree.lua',
  dependencies = {
    { 'nvim-tree/nvim-web-devicons' },
    {
      'yamatsum/nvim-nonicons',
      dependencies = { 'kyazdani42/nvim-web-devicons' },
      config = function()
        require('nvim-nonicons').setup()
      end
    },
  },
  config = function()
    local nonicons_extention = require("nvim-nonicons.extentions.nvim-tree")
    require("nvim-tree").setup({
      renderer = {
        icons = {
          glyphs = nonicons_extention.glyphs,
        },
      },
    })
  end,
  cmd = 'NvimTreeToggle',
  init = require('keymaps').nvim_tree(),
}
