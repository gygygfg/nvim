return {
  {
    -- Mason LSP服务
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require('plugins.lsp.mason_setup')
    end,
    dependencies = {
      "williamboman/mason.nvim",
    },
    -- event = "VeryLazy",
    init = require('keymaps').mason(),
    lazy = false,
  }, {
    -- :MasonUpdateAll — 更新所有已安装的 Mason 软件包
    "RubixDev/mason-update-all",
    config = function()
      require('mason-update-all').setup()
    end,
    dependencies = "williamboman/mason.nvim",
    -- event = 'VeryLazy',
    cmd = "MasonUpdateAll",
  }, {
    -- LSP自动补全
    "hrsh7th/nvim-cmp",
    dependencies = {
      -- 核心插件
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",   --neovim 内置 LSP 客户端的 nvim-cmp 源
      "hrsh7th/cmp-buffer",     --从buffer中智能提示
      "hrsh7th/cmp-nvim-lua",   --nvim-cmp source for neovim Lua API.
      "hrsh7th/cmp-path",       --自动提示硬盘上的文件
      "hrsh7th/cmp-cmdline",
      --
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",         --代码段合集
      "onsails/lspkind-nvim",                 --美化自动完成提示信息
      "octaltree/cmp-look",                   --用于完成英语单词
      "f3fora/cmp-spell",                     --nvim-cmp 的拼写源基于 vim 的拼写建议
      'lukas-reineke/cmp-under-comparator',   --cmp排序

      "amarakon/nvim-cmp-fonts",
      -- async path
      -- "FelipeLema/cmp-async-path",
      -- "lukas-reineke/cmp-rg",
      -- "akinsho/bufferline.nvim",
    },
    config = function()
      require("plugins.lsp.cmp_setup")
    end,
    lazy = false,
    -- event = "VeryLazy",
  }
}
