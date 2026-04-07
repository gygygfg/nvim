-- ~/.config/nvim/lua/lsp/init.lua
-- 稳定的 LSP 配置

local M = {}

-- 文件类型到 LSP 服务器的映射
M.filetype_to_lsp = {
  lua = "lua_ls",
  python = "pyright",
  javascript = "tsserver",
  typescript = "tsserver",
  javascriptreact = "tsserver",
  typescriptreact = "tsserver",
  html = "html",
  css = "cssls",
  json = "jsonls",
  yaml = "yamlls",
  yml = "yamlls",
  bash = "bashls",
  sh = "bashls",
  c = "clangd",
  cpp = "clangd",
  go = "gopls",
  rust = "rust_analyzer",
  java = "jdtls",
  markdown = "marksman",
  dockerfile = "dockerls",
  sql = "sqlls",
  tex = "texlab",
}

-- LSP 服务器配置
M.server_configs = {
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        diagnostics = {
          globals = { 'vim' },
          disable = { 'different-requires' }
        },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false
        },
        telemetry = { enable = false }
      }
    },
    single_file_support = true,
  },

  pyright = {
    settings = {
      python = {
        analysis = {
          typeCheckingMode = "basic",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true
        }
      }
    },
    single_file_support = true,
  },

  tsserver = {
    settings = {
      typescript = {
        format = { enable = true }
      },
      javascript = {
        format = { enable = true }
      }
    },
    single_file_support = true,
  },

  html = {
    single_file_support = true,
  },

  cssls = {
    single_file_support = true,
  },

  jsonls = {
    single_file_support = true,
  },

  yamlls = {
    single_file_support = true,
  },

  bashls = {
    single_file_support = true,
  },

  clangd = {
    single_file_support = true,
  },

  gopls = {
    single_file_support = true,
  },

  rust_analyzer = {
    single_file_support = true,
  },
}

-- 设置全局按键映射
local function setup_global_keymaps()
  -- 悬停文档
  vim.keymap.set('n', 'K', function()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if #clients > 0 then
      vim.lsp.buf.hover()
    else
      vim.notify("没有活动的 LSP 客户端", vim.log.levels.WARN)
    end
  end, { desc = '显示悬停文档' })

  -- 跳转到定义
  vim.keymap.set('n', 'gd', function()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if #clients > 0 then
      vim.lsp.buf.definition()
    else
      vim.notify("没有活动的 LSP 客户端", vim.log.levels.WARN)
    end
  end, { desc = '跳转到定义' })

  -- 代码操作
  vim.keymap.set({ 'n', 'v' }, '<leader>ca', function()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if #clients > 0 then
      vim.lsp.buf.code_action()
    else
      vim.notify("没有活动的 LSP 客户端", vim.log.levels.WARN)
    end
  end, { desc = '代码操作' })

  -- 重命名
  vim.keymap.set('n', '<leader>rn', function()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if #clients > 0 then
      vim.lsp.buf.rename()
    else
      vim.notify("没有活动的 LSP 客户端", vim.log.levels.WARN)
    end
  end, { desc = '重命名符号' })

  -- 格式化（安全版）
  vim.keymap.set({ 'n', 'v' }, '<leader>cf', function()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })

    -- 检查是否有支持格式化的客户端
    local formatting_clients = {}
    for _, client in ipairs(clients) do
      if client.supports_method("textDocument/formatting") then
        table.insert(formatting_clients, client.name)
      end
    end

    if #formatting_clients > 0 then
      vim.lsp.buf.format({ async = true })
      vim.notify("正在格式化... (" .. table.concat(formatting_clients, ", ") .. ")", vim.log.levels.INFO)
    else
      vim.notify("没有支持格式化的 LSP 客户端", vim.log.levels.WARN)
    end
  end, { desc = '格式化文档' })

  -- 查看引用
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = '查看引用' })
  -- 查看实现
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = '查看实现' })
  -- 类型定义
  vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, { desc = '跳转到类型定义' })
  -- 签名帮助
  vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { desc = '签名帮助' })
end

-- 设置诊断
local function setup_diagnostics()
  vim.diagnostic.config({
    virtual_text = {
      prefix = "●",
      spacing = 2,
    },
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  })

  -- 设置诊断符号
  local signs = {
    Error = "",
    Warn = "",
    Hint = "",
    Info = ""
  }

  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end
end

-- 启动文件类型的 LSP
local function start_lsp_for_filetype(ft, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- 避免重复启动
  if vim.b[bufnr].lsp_started then
    return
  end

  local server_name = M.filetype_to_lsp[ft]
  if not server_name then
    return
  end

  local config = M.server_configs[server_name] or {}

  -- 使用 pcall 安全地启动 LSP
  local success, err = pcall(vim.lsp.enable, server_name, config)
  if success then
    vim.b[bufnr].lsp_started = true
    vim.notify("LSP: " .. server_name .. " 已启用", vim.log.levels.INFO)
  else
    vim.notify("启动 LSP " .. server_name .. " 失败: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- 主设置函数
function M.setup()
  -- 设置诊断
  setup_diagnostics()

  -- 设置全局按键映射
  setup_global_keymaps()

  -- 文件类型自动命令
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("LSPFileType", { clear = true }),
    pattern = "*",
    callback = function(args)
      local ft = vim.bo.filetype
      if ft and ft ~= "" then
        vim.schedule(function()
          start_lsp_for_filetype(ft, args.buf)
        end)
      end
    end,
  })

  -- 已有的文件
  vim.api.nvim_create_autocmd("BufRead", {
    group = vim.api.nvim_create_augroup("LSPBufRead", { clear = true }),
    callback = function(args)
      local ft = vim.bo.filetype
      if ft and ft ~= "" and not vim.b[args.buf].lsp_started then
        vim.schedule(function()
          start_lsp_for_filetype(ft, args.buf)
        end)
      end
    end,
  })

  -- 保存时自动格式化
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("LSPAutoFormat", { clear = true }),
    callback = function(args)
      local bufnr = args.buf
      local clients = vim.lsp.get_clients({ bufnr = bufnr })

      -- 检查是否有支持格式化的客户端
      local can_format = false
      for _, client in ipairs(clients) do
        if client.supports_method("textDocument/formatting") then
          can_format = true
          break
        end
      end

      if can_format and vim.g.auto_format ~= false then
        -- 使用 pcall 避免格式化失败导致保存失败
        local success = pcall(vim.lsp.buf.format, {
          async = false,
          bufnr = bufnr
        })

        if not success then
          vim.notify("自动格式化失败", vim.log.levels.WARN)
        end
      end
    end,
  })

  -- 初始化 Mason
  M.setup_mason()

  print("LSP 配置已加载")
end

-- Mason 设置
function M.setup_mason()
  local mason_ok, mason = pcall(require, "mason")
  if not mason_ok then
    vim.notify("Mason 插件未加载", vim.log.levels.WARN)
    return
  end

  mason.setup({
    ui = {
      border = "rounded",
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗"
      }
    }
  })

  -- 安装推荐的 LSP 服务器
  vim.defer_fn(function()
    M.ensure_lsp_servers()
  end, 1000)
end

-- 确保 LSP 服务器已安装
function M.ensure_lsp_servers()
  local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_registry_ok then
    return
  end

  -- Mason 包名映射
  local lsp_to_mason = {
    lua_ls = "lua-language-server",
    pyright = "pyright",
    tsserver = "typescript-language-server",
    html = "html-lsp",
    cssls = "css-lsp",
    jsonls = "json-lsp",
    yamlls = "yaml-language-server",
    bashls = "bash-language-server",
    clangd = "clangd",
    gopls = "gopls",
    rust_analyzer = "rust-analyzer",
  }

  local installed = 0
  local to_install = {}

  for lsp_name, mason_name in pairs(lsp_to_mason) do
    local ok, pkg = pcall(mason_registry.get_package, mason_name)
    if ok and pkg:is_installed() then
      installed = installed + 1
    else
      table.insert(to_install, { lsp_name, mason_name })
    end
  end

  if #to_install > 0 then
    vim.notify("有 " .. #to_install .. " 个 LSP 服务器需要安装，运行 :LspInstallMissing 安装", vim.log.levels.INFO)
  else
    vim.notify("所有 LSP 服务器已安装 (" .. installed .. " 个)", vim.log.levels.INFO)
  end
end

-- 创建命令
vim.api.nvim_create_user_command("LspInstallMissing", function()
  local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_registry_ok then
    vim.notify("无法访问 Mason 注册表", vim.log.levels.ERROR)
    return
  end

  local lsp_to_mason = {
    lua_ls = "lua-language-server",
    pyright = "pyright",
    tsserver = "typescript-language-server",
    html = "html-lsp",
    cssls = "css-lsp",
    jsonls = "json-lsp",
    yamlls = "yaml-language-server",
    bashls = "bash-language-server",
    clangd = "clangd",
    gopls = "gopls",
    rust_analyzer = "rust-analyzer",
  }

  local installed = 0
  for lsp_name, mason_name in pairs(lsp_to_mason) do
    local ok, pkg = pcall(mason_registry.get_package, mason_name)
    if ok and not pkg:is_installed() then
      pkg:install()
      vim.notify("正在安装: " .. mason_name, vim.log.levels.INFO)
      installed = installed + 1
    end
  end

  if installed > 0 then
    vim.notify("已开始安装 " .. installed .. " 个 LSP 服务器", vim.log.levels.INFO)
  else
    vim.notify("所有 LSP 服务器已安装", vim.log.levels.INFO)
  end
end, { desc = "安装缺失的 LSP 服务器" })

vim.api.nvim_create_user_command("LspStatus", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if #clients == 0 then
    print("当前缓冲区没有活动的 LSP 客户端")
  else
    print("当前缓冲区的 LSP 客户端:")
    for _, client in ipairs(clients) do
      print("  - " .. client.name)
      print("    格式化支持: " .. tostring(client.supports_method("textDocument/formatting")))
      print("    悬停支持: " .. tostring(client.supports_method("textDocument/hover")))
    end
  end

  print("文件类型: " .. vim.bo.filetype)
  local server_name = M.filetype_to_lsp[vim.bo.filetype]
  if server_name then
    print("配置的 LSP 服务器: " .. server_name)
  end
end, { desc = "显示 LSP 状态" })

return M
