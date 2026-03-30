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
    -- LSP 基础配置
    "neovim/nvim-lspconfig",
    config = function()
      -- 基础 LSP 配置
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          -- 启用自动补全触发
          vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
          
          -- 按键映射
          local opts = { buffer = ev.buf }
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
          vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
          vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
          vim.keymap.set('n', '<space>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, opts)
          vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
          vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', '<space>f', function()
            vim.lsp.buf.format { async = true }
          end, opts)
        end,
      })
    end,
    lazy = false,
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
