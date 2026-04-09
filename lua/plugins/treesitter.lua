-- lua/plugins/treesitter.lua
vim.pack.add({
  -- 使用 vim.pack 安装 nvim-treesitter
  gh("nvim-treesitter/nvim-treesitter"),
  -- branch = "main", -- 注意：默认分支已从 master 改为 main
  -- run = ":TSUpdate", -- 安装后自动更新解析器
  gh("nvim-lua/plenary.nvim"),
})

require("nvim-treesitter").install({ "rust", "python", "typescript" })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "rust", "python", "typescript" },
  callback = function()
    vim.treesitter.start() -- highlighting
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- folds
    vim.wo.foldmethod = "expr"
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" -- indentation
  end,
})
