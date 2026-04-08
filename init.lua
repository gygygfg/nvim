-- ~/.config/nvim/init.lua
-- Neovim 主入口文件 - 基于 vim.pack 插件管理器

-- 1. 基础设置

-- 获取配置目录并添加到 package.path
local config_dir = vim.fn.fnamemodify(vim.fn.expand('<sfile>'), ':p:h')
local lua_dir = config_dir .. '/lua'
package.path = package.path .. ';' .. lua_dir .. '/?.lua;' .. lua_dir .. '/?/init.lua'

-- 确保插件目录存在
local function ensure_dir(path)
  vim.fn.mkdir(path, "p")
end
ensure_dir(vim.fn.stdpath("data") .. "/site/pack/core/opt")

-- 2. 插件声明 (使用 vim.pack.add)
-- 所有插件默认放置在 opt/ 目录，按需加载

-- 辅助函数：简化 GitHub 地址书写
_G.gh = function(x)
  return 'https://github.com/' .. x
end

vim.pack.add({
  -- 安装软件包而不加载
  -- 主题相关
  gh('folke/tokyonight.nvim'),
  gh('nvim-tree/nvim-web-devicons'),
  -- 界面增强
  gh('nvim-lualine/lualine.nvim'),
  gh('akinsho/bufferline.nvim'),
  gh('folke/noice.nvim'),
  gh('rcarriga/nvim-notify'),
  -- 文件浏览
  gh('nvim-tree/nvim-tree.lua'),
  -- 编辑增强
  gh('nvim-treesitter/nvim-treesitter'),
  gh('windwp/nvim-autopairs'),
  gh('numToStr/Comment.nvim'),
  gh('L3MON4D3/LuaSnip'),
  gh('hrsh7th/nvim-cmp'),
  gh('hrsh7th/cmp-nvim-lsp'),
  gh('hrsh7th/cmp-buffer'),
  gh('hrsh7th/cmp-path'),
  gh('hrsh7th/cmp-cmdline'),
  gh('saadparwaiz1/cmp_luasnip'),
  -- 模糊搜索
  gh('nvim-telescope/telescope.nvim'),
  gh('nvim-lua/plenary.nvim'),
  -- Git 集成
  gh('tpope/vim-fugitive'),
  gh('sindrets/diffview.nvim'),
  gh('lewis6991/gitsigns.nvim'),
  -- LSP 相关
  -- gh('neovim/nvim-lspconfig'),
  gh('j-hui/fidget.nvim'),
  gh('stevearc/dressing.nvim'),
  gh('folke/trouble.nvim'),
  gh('folke/which-key.nvim'),
  gh('neovim/nvim-lspconfig'), -- 虽然0.12有内置lsp，但这个插件提供更好配置
  -- Mason 和相关插件
  gh('williamboman/mason.nvim'),
  gh('williamboman/mason-lspconfig.nvim'),
  -- Formatter & Linter
  gh('nvimtools/none-ls.nvim'),
  gh('jay-babu/mason-null-ls.nvim'),
  -- 如果需要补全，可以添加这些插件
  gh('hrsh7th/nvim-cmp'),
  gh('hrsh7th/cmp-nvim-lsp'),
  gh('hrsh7th/cmp-buffer'),
  gh('hrsh7th/cmp-path'),
  gh('hrsh7th/cmp-cmdline'),
  gh('saadparwaiz1/cmp_luasnip'),
  gh('L3MON4D3/LuaSnip'),
  -- AI 辅助
  gh('olimorris/codecompanion.nvim'),
  gh('github/copilot.vim'),
  -- 工具类
  gh('nvim-lua/popup.nvim'),
})
-- 3. 加载核心配置

-- 加载基础选项和按键映射
require('core.notify_config')
require("core.options")
require("core.keymaps")
require("core.autocommands")

-- 加载LSP配置
require("lsp").setup()

require('plugins-manager').setup({
  -- 4. 加载插件配置
  auto_load = true, -- 自动加载所有插件
  -- print_list = true -- 打印可用插件列表
})

-- 通知用户配置已加载
vim.notify("Neovim 配置加载完成", vim.log.levels.INFO)
