return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require 'nvim-treesitter'.setup({
      ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "python", "javascript", "typescript", "html", "css", "json", "yaml" },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = true },
      textobjects = {
        select = { enable = true },
        move = {
          enable = true,
          set_jumps = false, -- 改为 false，仅当前文件内跳转
          goto_next_start = {
            [']f'] = '@function.outer',
            [']m'] = '@class.outer'
          },
          goto_previous_start = {
            ['[f'] = '@function.outer',
            ['[m'] = '@class.outer'
          },
        },
      },
    })
  end,
  init = require("keymaps").treesitter_textobjects,
  event = "VeryLazy",
}
