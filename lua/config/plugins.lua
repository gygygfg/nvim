-- 插件配置
-- 使用 load.addPack 添加插件

local M = {}

M.setup = function()
  -- 添加核心插件
  load.addPack({
    -- Mason - LSP、DAP、Linter、Formatter 管理器
    {
      'williamboman/mason.nvim',
      config = function()
        -- 配置在 lsp/init.lua 中通过 load.require 设置
      end
    },
    
    -- Mason LSP 配置
    {
      'williamboman/mason-lspconfig.nvim',
      dependencies = { 'williamboman/mason.nvim' },
      config = function()
        -- 配置在 lsp/init.lua 中通过 load.require 设置
      end
    },
    
    -- nvim-treesitter
    {
      'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate',
      config = function()
        require('nvim-treesitter.configs').setup({
          ensure_installed = { 'lua', 'vim', 'vimdoc', 'query', 'python', 'javascript', 'typescript', 'html', 'css', 'json', 'markdown' },
          sync_install = false,
          auto_install = true,
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
          },
        })
      end
    },
    
    -- nvim-autopairs
    {
      'windwp/nvim-autopairs',
      event = 'InsertEnter',
      config = true
    },
    
    -- Comment.nvim
    {
      'numToStr/Comment.nvim',
      config = true
    },
    
    -- nvim-tree
    {
      'nvim-tree/nvim-tree.lua',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      config = function()
        require('nvim-tree').setup({
          view = {
            width = 30,
          },
        })
      end
    },
    
    -- bufferline
    {
      'akinsho/bufferline.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      config = function()
        require('bufferline').setup({
          options = {
            mode = 'tabs',
            separator_style = 'slant',
          },
        })
      end
    },
    
    -- lualine
    {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      config = function()
        require('lualine').setup({
          options = {
            theme = 'auto',
          },
        })
      end
    },
    
    -- nvim-web-devicons (图标)
    {
      'nvim-tree/nvim-web-devicons',
      config = true
    },
    
    -- mcphub (如果存在)
    {
      'mcphub/mcphub.nvim',
      config = function()
        require('mcphub').setup({})
      end
    }
  })
end

return M