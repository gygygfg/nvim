-- Lua语言服务器配置
return {
  name = "lua_ls",
  cmd = { "lua-language-server" },
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = {
          '?.lua',
          '?/init.lua',
          vim.fn.expand('~/.config/nvim/lua/?.lua'),
          vim.fn.expand('~/.config/nvim/lua/?/init.lua'),
        },
      },
      diagnostics = {
        globals = { 
          'vim', 'gh', 
          -- Neovim API 全局变量
          'nvim', 'packer', 'lazy',
          -- 常用模块
          'require', 'package',
          -- 调试变量
          'DEBUG', 'TEST',
        },
        disable = { 'undefined-global' },
      },
      workspace = {
        library = {
          -- Neovim 运行时库
          [vim.fn.expand('$VIMRUNTIME/lua')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim/pack')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim/api')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim/fn')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim/lua')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim/shared')] = true,
          
          -- 用户配置
          [vim.fn.expand('~/.config/nvim')] = true,
          [vim.fn.expand('~/.config/nvim/lua')] = true,
          
          -- 插件管理器路径
          [vim.fn.expand('~/.local/share/nvim/lazy')] = true,
          [vim.fn.expand('~/.local/share/nvim/site/pack')] = true,
          
          -- 标准库路径（用于 require 解析）
          [vim.fn.expand('/usr/share/nvim/runtime/lua')] = true,
          [vim.fn.expand('/usr/local/share/nvim/runtime/lua')] = true,
        },
        maxPreload = 10000,
        preloadFileSize = 10000,
        checkThirdParty = false,
      },
      completion = {
        callSnippet = 'Replace',
        keywordSnippet = 'Replace',
      },
      hint = {
        enable = true,
        arrayIndex = 'Disable',
        await = true,
        paramName = 'Disable',
        paramType = false,
        semicolon = 'Disable',
        setType = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
  filetypes = { "lua" },
}
