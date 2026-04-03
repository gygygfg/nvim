-- lua/config/treesitter.lua
-- 语法高亮插件配置，按需加载

vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})

vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  -- 在首次打开文件时加载 nvim-treesitter
  pattern = '*',
  once = false,
  callback = function(args)
    -- 检查插件是否已加载
    if not package.loaded['nvim-treesitter'] then
      -- 加载插件
      require('nvim-treesitter').setup({
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
    end
  end,
})
