-- lua/config/editor.lua
-- 编辑器增强配置

-- nvim-autopairs - 自动括号配对
require("nvim-autopairs").setup({
  check_ts = true,
  ts_config = {
    lua = { "string" },
    javascript = { "template_string" },
  },
})

-- Comment.nvim - 注释工具
require("Comment").setup({
  toggler = {
    line = "gcc",
    block = "gbc",
  },
  opleader = {
    line = "gc",
    block = "gb",
  },
})
