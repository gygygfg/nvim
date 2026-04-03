-- lua/config/lsp/init.lua
-- LSP 配置 (Neovim 0.12+ API)

-- lua/config/lsp/init.lua已加载

-- 立即加载 LSP 核心插件
vim.cmd('packadd mason.nvim')
vim.cmd('packadd mason-lspconfig.nvim')
vim.cmd('packadd nvim-lspconfig')

-- 初始化 Mason（如果可用）
local mason_ok, mason = pcall(require, 'mason')
if mason_ok then
  mason.setup()
  -- Mason初始化完成
else
  vim.notify('Mason未安装或加载失败', vim.log.levels.WARN)
end

-- 设置 LSP 按键映射（在LSP附加时）
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
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

-- 配置基础LSP服务器（使用Neovim 0.12新API）
local function setup_lsp_servers()
  -- Lua LSP (lua_ls)
  vim.lsp.config('lua_ls', {
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT',
        },
        diagnostics = {
          globals = { 'vim' },
        },
        workspace = {
          library = vim.api.nvim_get_runtime_file('', true),
          checkThirdParty = false,
        },
        telemetry = {
          enable = false,
        },
      },
    },
  })

  -- Python LSP (pyright)
  vim.lsp.config('pyright', {
    cmd = {'pyright-langserver', '--stdio'},
    filetypes = {'python'},
    root_markers = {'.git', 'pyproject.toml', 'setup.py'},
    settings = {
      python = {
        analysis = {
          typeCheckingMode = 'strict',
          autoSearchPaths = true,
        },
      },
    },
  })

  -- TypeScript/JavaScript LSP (ts_ls)
  vim.lsp.config('ts_ls', {
    filetypes = {'javascript', 'typescript', 'javascriptreact', 'typescriptreact'},
    settings = {
      javascript = {
        inlayHints = {
          includeInlayParameterNameHints = 'all',
        },
      },
      typescript = {
        inlayHints = {
          includeInlayParameterNameHints = 'all',
        },
      },
    },
  })

  -- LSP服务器配置完成
end

-- 延迟加载LSP服务器配置
vim.api.nvim_create_autocmd('FileType', {
  pattern = {'lua', 'python', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact'},
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    
    -- 启用对应的LSP服务器
    if ft == 'lua' then
      vim.lsp.enable('lua_ls')
    elseif ft == 'python' then
      vim.lsp.enable('pyright')
    elseif ft == 'javascript' or ft == 'typescript' or ft == 'javascriptreact' or ft == 'typescriptreact' then
      vim.lsp.enable('ts_ls')
    end
    
    -- 已为 ' .. ft .. ' 文件类型启用LSP
  end,
})

-- 调用配置函数
setup_lsp_servers()

-- LSP配置完成
