-- ~/.config/nvim/lua/plugins/gitsigns.lua
return {
  "lewis6991/gitsigns.nvim",
  event = "BufReadPre",
  opts = {
    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
    },
    current_line_blame = true, -- 在状态栏显示当前行 blame
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol", -- eol|overlay|right_align
      delay = 1000,
      ignore_whitespace = false,
    },
  }
}