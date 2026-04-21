-- Lua语言服务器配置（内存优化版）
return {
  name = "lua_ls",
  cmd = { "lua-language-server" },
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        -- 简化路径配置，减少搜索范围
        path = {
          '?.lua',
          '?/init.lua',
          vim.fn.expand('~/.config/nvim/lua/?.lua'),
          vim.fn.expand('~/.config/nvim/lua/?/init.lua'),
        },
      },
      diagnostics = {
        -- 精简全局变量列表
        globals = { 
          'vim', 'gh',
          -- 仅保留必要的全局变量
          'require', 'package',
        },
        -- 启用更多诊断以减少内存使用
        disable = { 'undefined-global', 'unused-local', 'unused-vararg' },
        -- 限制诊断范围
        severity = {
          ['undefined-global'] = "Warning",
        },
        -- 减少不必要的诊断
        neededFileStatus = {
          ["codestyle-check"] = "Any",
        },
      },
      workspace = {
        library = {
          -- 仅保留必要的运行时库
          [vim.fn.expand('$VIMRUNTIME/lua')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim')] = true,
          
          -- 用户配置（必需）
          [vim.fn.expand('~/.config/nvim')] = true,
          [vim.fn.expand('~/.config/nvim/lua')] = true,
          
          -- 插件管理器路径（仅保留一个）
          [vim.fn.expand('~/.local/share/nvim/lazy')] = true,
        },
        -- 大幅减少预加载文件数量以节省内存
        maxPreload = 1000,  -- 从 10000 减少到 1000
        preloadFileSize = 2000,  -- 从 10000 减少到 2000
        checkThirdParty = false,
        -- 禁用不必要的 workspace 扫描
        ignoreDir = { ".git", "node_modules", "target", "dist", "build" },
        -- 限制 workspace 大小
        maxPreloadFiles = 500,
      },
      completion = {
        callSnippet = 'Replace',
        keywordSnippet = 'Replace',
        -- 限制自动完成项目数量
        maxItems = 50,
        -- 禁用一些耗内存的完成功能
        autoRequire = false,
      },
      hint = {
        enable = true,
        -- 禁用一些提示以减少内存使用
        arrayIndex = 'Disable',
        await = false,  -- 禁用 await 提示
        paramName = 'Disable',
        paramType = false,
        semicolon = 'Disable',
        setType = false,
      },
      -- 内存优化设置
      misc = {
        -- 减少内存使用
        parameters = {
          ["Lua.workspace.maxPreload"] = 1000,
          ["Lua.workspace.preloadFileSize"] = 2000,
        },
      },
      telemetry = {
        enable = false,
      },
      -- 代码格式化设置（减少内存使用）
      format = {
        enable = true,
        defaultConfig = {
          indent_style = "space",
          indent_size = "2",
          quote_style = "auto",
        },
      },
    },
  },
  filetypes = { "lua" },
  -- 添加初始化选项以减少内存使用
  init_options = {
    -- 禁用一些耗内存的功能
    hover = true,
    completion = true,
    signatureHelp = true,
    -- 限制内存使用
    memory = {
      max = 256,  -- 最大内存使用（MB）
    },
  },
}
