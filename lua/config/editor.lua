-- 编辑增强插件配置

vim.pack.add({
  -- nvim-treesitter - 语法高亮（配置在 treesitter.lua 中）
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  -- nvim-autopairs - 自动括号配对
  { src = "https://github.com/windwp/nvim-autopairs" },
  -- comment.nvim - 注释工具
  { src = "https://github.com/numToStr/Comment.nvim" },
})

vim.api.nvim_create_autocmd('VimEnter', {
	    callback = function()
require("nvim-autopairs").setup({
-- 配置 nvim-autopairs
  check_ts = true,
  ts_config = {
    lua = { "string" },
    javascript = { "template_string" },
  },
})

require("Comment").setup({
-- 配置 comment.nvim
  toggler = {
    line = "gcc",
    block = "gbc",
  },
  opleader = {
    line = "gc",
    block = "gb",
  },
})
end
})
