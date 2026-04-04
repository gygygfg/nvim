-- 编辑增强插件配置

-- 使用 load 包装函数收集包信息
load.addPack({
  -- nvim-treesitter - 语法高亮（配置在 treesitter.lua 中）
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  -- nvim-autopairs - 自动括号配对
  { src = "https://github.com/windwp/nvim-autopairs" },
  -- comment.nvim - 注释工具
  { src = "https://github.com/numToStr/Comment.nvim" },
})

-- 使用 load 包装函数注册 autocmd
load.nvim_create_autocmd('VimEnter', {
  callback = function()
    -- 配置 nvim-autopairs
    require("nvim-autopairs").setup({
      check_ts = true,
      ts_config = {
        lua = { "string" },
        javascript = { "template_string" },
      },
    })

    -- 配置 comment.nvim
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
  end
})

-- 使用 load 包装函数声明需要 require 的模块
-- 注意：这里只是声明，实际的 require 会在所有包添加后执行
load.require('nvim-treesitter.configs')
load.require('nvim-autopairs')
load.require('Comment')

print('编辑器配置已加载（使用新的 load 包装函数）')
