return {
  {
    -- Mason 核心插件
    "williamboman/mason.nvim",
    config = function()
      require('plugins.lsp.mason.init').setup()
    end,
    lazy = false,
    init = require('keymaps').mason(),
  },
  {
    -- Mason LSP 配置
    "williamboman/mason-lspconfig.nvim",
    dependencies = "williamboman/mason.nvim",
    config = function()
      -- LSP 配置在 mason/init.lua 中处理
    end,
    lazy = false,
  },
  {
    -- Mason DAP 配置（可选）
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "mfussenegger/nvim-dap",
    },
    config = function()
      -- DAP 配置在 mason/init.lua 中处理
    end,
    lazy = false,
  },
  {
    -- Mason 工具安装器（Linter/Formatter）
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = "williamboman/mason.nvim",
    config = function()
      -- 工具安装器配置在 mason/init.lua 中处理
    end,
    lazy = false,
  },
  {
    -- :MasonUpdateAll — 更新所有已安装的 Mason 软件包
    "RubixDev/mason-update-all",
    dependencies = "williamboman/mason.nvim",
    config = function()
      require('mason-update-all').setup()
    end,
    cmd = "MasonUpdateAll",
  },
  {
    -- LSP自动补全
    "hrsh7th/nvim-cmp",
    dependencies = {
      -- 核心插件
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp", --neovim 内置 LSP 客户端的 nvim-cmp 源
      "hrsh7th/cmp-buffer",   --从buffer中智能提示
      "hrsh7th/cmp-nvim-lua", --nvim-cmp source for neovim Lua API.
      "hrsh7th/cmp-path",     --自动提示硬盘上的文件
      "hrsh7th/cmp-cmdline",
      --
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",       --代码段合集
      "onsails/lspkind-nvim",               --美化自动完成提示信息
      "octaltree/cmp-look",                 --用于完成英语单词
      "f3fora/cmp-spell",                   --nvim-cmp 的拼写源基于 vim 的拼写建议
      'lukas-reineke/cmp-under-comparator', --cmp排序

      "amarakon/nvim-cmp-fonts",
    },
    config = function()
      require("plugins.lsp.cmp_setup")
    end,
    lazy = false,
  }
}
