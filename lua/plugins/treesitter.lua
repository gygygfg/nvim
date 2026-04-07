-- lua/config/treesitter.lua
-- Treesitter 语法高亮配置

require('nvim-treesitter.configs').setup({
  ensure_installed = {
    "lua", "vim", "vimdoc", "bash", "python",
    "javascript", "typescript", "html", "css", "json"
  },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = { enable = true },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<CR>",
      node_incremental = "<CR>",
      node_decremental = "<BS>",
    },
  },
})
