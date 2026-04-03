-- LSP 相关插件配置

vim.pack.add({
  -- nvim-lspconfig - LSP 配置
  { src = "https://github.com/neovim/nvim-lspconfig" },
  -- mason.nvim - 包管理器
  { src = "https://github.com/mason-org/mason.nvim" },
  -- mason-lspconfig.nvim - Mason LSP 配置
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  -- nvim-cmp - 自动补全
  { src = "https://github.com/hrsh7th/nvim-cmp" },
  -- cmp-nvim-lsp - LSP 补全源
  { src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
  -- cmp-buffer - 缓冲区补全源
  { src = "https://github.com/hrsh7th/cmp-buffer" },
  -- cmp-path - 路径补全源
  { src = "https://github.com/hrsh7th/cmp-path" },
  -- cmp-cmdline - 命令行补全源
  { src = "https://github.com/hrsh7th/cmp-cmdline" },
  -- LuaSnip - 代码片段
  { src = "https://github.com/L3MON4D3/LuaSnip" },
  -- cmp_luasnip - LuaSnip 补全源
  { src = "https://github.com/saadparwaiz1/cmp_luasnip" },
})

vim.api.nvim_create_autocmd('VimEnter', {
	callback = function()
-- 配置 mason
require("mason").setup()

-- 配置 mason-lspconfig
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "tsserver",
    "pyright",
    "html",
    "cssls",
    "jsonls",
    "yamlls",
    "bashls",
  },
})

-- 配置 nvim-cmp
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
  }),
})

-- 配置 LSP
local lspconfig = require("lspconfig")

-- Lua LSP 配置
lspconfig.lua_ls.setup({
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

-- 其他 LSP 配置可以在这里添加
end
})
