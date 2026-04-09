-- lua/config/nvim_tree.lua
-- Nvim-tree 文件树配置

vim.api.nvim_create_autocmd({ "BufRead", "BufEnter" }, {
  -- 状态栏和缓冲区 - 启动后加载
  once = true,
  callback = function()
    require("nvim-tree").setup({
      sort_by = "case_sensitive",
      view = {
        width = 30,
        side = "left",
      },
      renderer = {
        group_empty = true,
        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },
          glyphs = {
            default = "",
            symlink = "",
            folder = {
              default = "",
              open = "",
              empty = "",
              empty_open = "",
              symlink = "",
              symlink_open = "",
            },
            git = {
              unstaged = "",
              staged = "S",
              unmerged = "",
              renamed = "➜",
              untracked = "U",
              deleted = "",
              ignored = "◌",
            },
          },
        },
      },
      filters = {
        dotfiles = false,
      },
    })
  end,
})

vim.keymap.set("n", "<leader>d", function()
  require("nvim-tree.api").tree.toggle()
end, { desc = "切换文件树" })
