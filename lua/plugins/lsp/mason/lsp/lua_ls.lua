-- Mason lsp 配置
-- 迁移自: servers/lua_ls.lua
-- 时间: 2026-03-29 20:37:04

-- Mason 安装: lua_ls
local neovim_globals = {
  -- Neovim API
  'vim', 'nvim',

  -- 常用插件开发全局变量
  'packer_plugins', 'lazy', 'use',

  -- 测试相关
  'describe', 'it', 'before_each', 'after_each', 'setup', 'teardown',

  -- 其他常见全局变量
  'DEBUG', 'TEMPLATE', 'MODULE',
}
return {
  capabilities = capabilities,

  settings = {
    Lua = {
      -- 指定 Lua 运行时版本
      runtime = {
        version = 'LuaJIT',
        -- 设置 Lua 模块的加载路径
        path = {
          '?.lua',
          '?/init.lua',
          'lua/?.lua',
          'lua/?/init.lua'
        }
      },

      -- 工作区设置
      workspace = {
        -- 让语言服务器知道 Neovim 运行时文件
        library = {
          vim.env.VIMRUNTIME,
          -- 如果你使用插件，可以添加插件路径
          vim.fn.stdpath("config") .. "/lua",
          -- "${3rd}/luv/library",
          -- "${3rd}/busted/library",
        },
        -- 避免将工作区设置为整个 Neovim 配置目录
        checkThirdParty = false,
        maxPreload = 10000,
        preloadFileSize = 1000,
      },

      -- 诊断设置
      diagnostics = {
        enable = true,
        -- globals = {
        --   -- 定义全局变量，避免被标记为未定义
        --   'vim',       -- Neovim 全局
        --   'use',       -- 懒加载插件常用
        --   'describe',  -- 测试框架
        --   'it',        -- 测试框架
        --   'before_each', -- 测试框架
        --   'after_each',  -- 测试框架
        -- },
        globals = neovim_globals,
        neededFileStatus = {
          ["ambiguity-1"] = "None",
          ["await-in-sync"] = "None",
          ["circle-doc-class"] = "None",
        },
        disable = { "undefined-global", "unused-local", "unused-function" },
        groupSeverity = {
          strong = "Warning",
          strict = "Warning"
        },
        groupFileStatus = {
          ["ambiguity-1"] = "None",
          ["await-in-sync"] = "None",
          ["circle-doc-class"] = "None",
        },
        unusedLocalExclude = {},
      },

      -- 代码补全设置
      completion = {
        callSnippet = "Replace", -- 显示函数调用片段
        keywordSnippet = "Replace",
        postfix = ".",           -- 触发补全的字符
        showWord = "Disable",
      },

      -- 语义令牌（语法高亮增强）
      semantic = {
        enable = true,
        annotation = true,
        keyword = true,
      },

      -- 格式化和代码操作
      format = {
        enable = true,
        defaultConfig = {
          indent_style = "space",
          indent_size = "2",
          quote_style = "single",
        }
      },

      -- 悬停和签名帮助
      hover = {
        enable = true,
        viewNumber = true,
        viewString = true,
        viewStringMax = 1000,
      },

      -- 遥测（可选禁用）
      telemetry = {
        enable = false
      }
    }
  },

  -- 单文件支持
  single_file_support = true,

  -- 根目录检测
  root_dir = function(fname)
    -- 对于 Neovim 配置，使用配置文件所在目录作为根目录
    if fname:match("nvim.*/lua/") then
      return vim.fn.fnamemodify(fname, ":h:h")
    end
    return require("lspconfig.util").root_pattern(".git", ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml",
      "stylua.toml", "selene.toml", "README.md")(fname)
  end,
}
