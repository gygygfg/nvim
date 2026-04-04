-- UI 增强插件配置

load.addPack({
  -- nvim-tree.lua - 文件树
  { src = "https://github.com/nvim-tree/nvim-tree.lua" },
  -- bufferline.nvim - 缓冲区标签栏
  { src = "https://github.com/akinsho/bufferline.nvim" },
  -- lualine.nvim - 状态栏
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
})

load.require("nvim-tree", {
  -- 配置 nvim-tree
  view = {
    width = 30,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
})

load.require("bufferline", {
  -- 配置 bufferline
  options = {
    -- 使用 nvim 内置lsp
    diagnostics = "nvim_lsp",
    -- 左侧让出 nvim-tree 的位置
    offsets = { {
      filetype = "NvimTree",
      text = "File Explorer",
      highlight = "Directory",
      text_align = "left"
    } }
  },
})

load.require("lualine", {
  -- 配置 lualine
  options = {
    theme = "tokyonight",
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = { "filename" },
    lualine_x = { "encoding", "fileformat", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
})
