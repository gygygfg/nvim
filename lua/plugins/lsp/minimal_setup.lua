-- 最小化的 LSP 设置
-- 完全绕过复杂的配置加载器

local M = {}

function M.setup()
  print("🚀 启动最小化 LSP 设置...")
  
  -- 获取 capabilities
  local capabilities = require("cmp_nvim_lsp").default_capabilities()
  
  -- 基本的 on_attach 函数
  local on_attach = function(client, bufnr)
    -- 启用 LSP 提供的格式化和代码操作
    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.documentRangeFormattingProvider = true
    
    -- 基本键映射
    local opts = { noremap = true, silent = true, buffer = bufnr }
    
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, opts)
  end
  
  -- 定义基本的 LSP 服务器配置
  local servers = {
    bashls = {
      filetypes = {"sh", "bash", "zsh"},
      cmd = {"bash-language-server", "start"}
    },
    lua_ls = {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = {"vim"} },
          workspace = { library = vim.api.nvim_get_runtime_file("", true) },
          telemetry = { enable = false }
        }
      }
    },
    pyright = {
      filetypes = {"python"},
      cmd = {"pyright-langserver", "--stdio"}
    },
    html = {
      filetypes = {"html"},
      cmd = {"html-lsp", "--stdio"}
    },
    tsserver = {
      filetypes = {"javascript", "javascriptreact", "typescript", "typescriptreact"},
      cmd = {"typescript-language-server", "--stdio"}
    },
    cssls = {
      filetypes = {"css", "scss", "less"},
      cmd = {"css-languageserver", "--stdio"}
    },
    jsonls = {
      filetypes = {"json", "jsonc"},
      cmd = {"json-languageserver", "--stdio"}
    },
    yamlls = {
      filetypes = {"yaml", "yml"},
      cmd = {"yaml-language-server", "--stdio"}
    },
    vimls = {
      filetypes = {"vim"},
      cmd = {"vim-language-server", "--stdio"}
    },
    clangd = {
      filetypes = {"c", "cpp", "objc", "objcpp"},
      cmd = {"clangd", "--background-index"}
    }
  }
  
  print("📋 配置 " .. #vim.tbl_keys(servers) .. " 个 LSP 服务器")
  
  local success_count = 0
  
  for server_name, config in pairs(servers) do
    -- 合并配置
    local server_config = vim.tbl_deep_extend("force", {
      capabilities = capabilities,
      on_attach = on_attach,
      single_file_support = true
    }, config)
    
    -- 使用正确的 vim.lsp.start() API 设置服务器
    local ok, err = pcall(function()
      vim.lsp.start({
        name = server_name,
        config = server_config
      })
    end)
    
    if ok then
      success_count = success_count + 1
      print("  ✅ " .. server_name)
    else
      print("  ❌ " .. server_name .. ": " .. tostring(err))
    end
  end
  
  print("\n🎉 完成: " .. success_count .. "/" .. #vim.tbl_keys(servers) .. " 个服务器配置成功")
  print("\n💡 提示: 打开相应文件类型的文件来激活 LSP")
end

-- 立即执行设置
M.setup()

return M