-- ~/.config/nvim/lua/lsp/init.lua
-- 集成 conform.nvim 的 LSP 配置

local M = {}

vim.pack.add({
  -- 安装但不加载需要插件
  -- LSP 相关
  gh("j-hui/fidget.nvim"),
  gh("stevearc/dressing.nvim"),
  gh("folke/trouble.nvim"),
  gh("folke/which-key.nvim"),
  -- gh("neovim/nvim-lspconfig"), -- 注释掉，完全使用 Neovim 0.12 内置 LSP API
  -- Mason 和相关插件
  gh("williamboman/mason.nvim"),
  gh("williamboman/mason-lspconfig.nvim"),
  -- Formatter & Linter
  gh("stevearc/conform.nvim"),
})

-- 配置选项
M.config = {
  -- 是否使用 nvim-lspconfig 插件
  -- 设置为 false 时，使用 Neovim 0.12 的内置 LSP API
  use_lspconfig = false,

  -- 是否启用调试模式
  debug = false,

  -- 是否自动格式化
  auto_format = true,
}

M.formatters_by_ft = {
  -- 格式化工具配置
  lua = { "stylua" },
  python = { "black", "isort" },
  javascript = { "prettierd", "prettier" },
  typescript = { "prettierd", "prettier" },
  javascriptreact = { "prettierd", "prettier" },
  typescriptreact = { "prettierd", "prettier" },
  html = { "prettierd", "prettier" },
  css = { "prettierd", "prettier" },
  json = { "prettierd", "prettier" },
  yaml = { "yamlfmt" },
  yml = { "yamlfmt" },
  bash = { "shfmt" },
  sh = { "shfmt" },
  c = { "clang-format" },
  cpp = { "clang-format" },
  go = { "gofumpt", "goimports" },
  rust = { "rustfmt" },
  java = { "google-java-format" },
  markdown = { "prettierd", "prettier" },
  sql = { "sql-formatter" },
  tex = { "latexindent" },
  ["*"] = { "codespell" }, -- 拼写检查
}

M.filetype_mappings = {
  -- 文件类型到 LSP 服务器的映射（支持多个服务器）
  -- Web 开发
  javascript = { "ts_ls", "html", "cssls" },
  typescript = { "ts_ls", "html", "cssls" },
  javascriptreact = { "ts_ls", "html", "cssls" },
  typescriptreact = { "ts_ls", "html", "cssls" },
  html = { "html", "cssls", "ts_ls" },
  css = { "cssls" },
  json = { "jsonls" },
  yaml = { "yamlls" },
  yml = { "yamlls" },

  -- 系统编程
  c = { "clangd", "html" },
  cpp = { "clangd", "html" },
  rust = { "rust_analyzer", "html" },
  go = { "gopls", "html" },

  -- 脚本语言
  lua = { "lua_ls" },
  python = { "pyright", "html", "cssls", "ts_ls" },
  sh = { "bashls" },
  zsh = { "bashls" },
  bash = { "bashls" },
}

M.lsp_to_mason = {
  -- LSP 服务器到 Mason 包名的映射
  lua_ls = "lua-language-server",
  pyright = "pyright",
  ts_ls = "typescript-language-server",
  html = "html-lsp",
  cssls = "css-lsp",
  jsonls = "json-lsp",
  yamlls = "yaml-language-server",
  bashls = "bash-language-server",
  clangd = "clangd",
  gopls = "gopls",
  rust_analyzer = "rust-analyzer",
}

M.formatter_to_mason = {
  -- 格式化工具到 Mason 包名的映射
  stylua = "stylua",
  prettier = "prettier",
  prettierd = "prettierd",
  black = "black",
  isort = "isort",
  yamlfmt = "yamlfmt",
  shfmt = "shfmt",
  ["clang-format"] = "clang-format",
  gofumpt = "gofumpt",
  goimports = "gofmt",
  rustfmt = "rustfmt",
  ["google-java-format"] = "google-java-format",
  ["sql-formatter"] = "sql-formatter",
  latexindent = "latexindent",
  codespell = "codespell",
}

-- 跳过 LSP 检查和格式化的文件类型
M.skip_filetypes = {
  notify = true, -- vim.notify 插件弹出的悬浮文本
  NvimTree = true, -- 文件管理器
  TelescopePrompt = true, -- Telescope 提示框
  packer = true, -- 插件管理器
  help = true, -- 帮助文档
  qf = true, -- 快速修复列表
  terminal = true, -- 终端
  [""] = true, -- 空文件类型
}

local function load_server_config(server_name)
  -- 动态加载 LSP 服务器配置
  local module_name = "lsp.configs." .. server_name

  -- 调试信息
  if vim.g.lsp_debug then
    vim.notify("[LSP] 尝试加载配置模块: " .. module_name)
  end

  local ok, config = pcall(require, module_name)
  if ok then
    return config
  else
    vim.notify("[LSP] 配置加载失败: " .. server_name)
    vim.notify("[LSP] 错误信息: " .. config)

    -- 调试模块路径
    vim.notify("[LSP] 调试模块路径:")

    -- 详细分析 package.path
    local paths = {}
    for path in package.path:gmatch("[^;]+") do
      table.insert(paths, path)
    end
    vim.notify("  package.path 包含 " .. #paths .. " 个路径")

    -- 显示前几个路径
    for i = 1, math.min(5, #paths) do
      vim.notify("    [" .. i .. "] " .. paths[i])
    end

    if #paths > 5 then
      vim.notify("    ... 还有 " .. (#paths - 5) .. " 个路径")
    end

    -- 尝试查找文件
    local config_path = vim.fn.expand("~/.config/nvim/lua/lsp/configs/" .. server_name .. ".lua")
    vim.notify("  配置文件路径: " .. config_path)
    vim.notify("  文件存在: " .. (vim.fn.filereadable(config_path) == 1 and "是" or "否"))

    -- 测试模块搜索
    vim.notify("  测试模块搜索:")
    local test_module = "lsp.configs." .. server_name
    local test_path = test_module:gsub("%.", "/") .. ".lua"
    vim.notify("    模块名: " .. test_module)
    vim.notify("    转换后路径: " .. test_path)

    -- 尝试在 package.path 中查找
    for i, path_pattern in ipairs(paths) do
      local test_file = path_pattern:gsub("%?", test_path)
      if vim.fn.filereadable(test_file) == 1 then
        vim.notify("    在路径 [" .. i .. "] 找到文件: " .. test_file)
        break
      end
    end
    return {}
  end
end

local function get_default_cmd(server_name)
  -- 为常见服务器提供默认的 cmd 值
  local default_cmds = {
    lua_ls = { "lua-language-server" },
    pyright = { "pyright-langserver", "--stdio" },
    ts_ls = { "typescript-language-server", "--stdio" },
    html = { "vscode-html-language-server", "--stdio" },
    cssls = { "vscode-css-language-server", "--stdio" },
    jsonls = { "vscode-json-language-server", "--stdio" },
    yamlls = { "yaml-language-server", "--stdio" },
    bashls = { "bash-language-server", "start" },
    clangd = { "clangd" },
    gopls = { "gopls" },
    rust_analyzer = { "rust-analyzer" },
  }

  return default_cmds[server_name]
end

local function get_available_servers()
  -- 获取所有可用的 LSP 服务器（从 configs 文件夹动态获取）
  local configs_dir = vim.fn.expand("~/.config/nvim/lua/lsp/configs")
  local servers = {}

  local handle = vim.loop.fs_scandir(configs_dir)
  if handle then
    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end

      -- 只处理 .lua 文件
      if type == "file" and name:match("%.lua$") then
        local server_name = name:gsub("%.lua$", "")
        table.insert(servers, server_name)
      end
    end
  end

  return servers
end

M.server_configs = setmetatable({}, {
  __index = function(_, server_name)
    return load_server_config(server_name)
  end,
})

M.get_available_servers = get_available_servers

local function has_active_lsp_client(bufnr)
  -- 检查当前缓冲区是否有活动的 LSP 客户端
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  return #clients > 0
end

local function safe_lsp_action(action, warning_msg)
  -- 安全执行 LSP 操作，如果没有活动客户端则显示警告
  local bufnr = vim.api.nvim_get_current_buf()
  if has_active_lsp_client(bufnr) then
    action()
  else
    vim.notify(warning_msg or "没有活动的 LSP 客户端", vim.log.levels.WARN)
  end
end

local function setup_conform()
  -- 设置 conform.nvim
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    vim.notify("conform.nvim 插件未加载，请确保已安装", vim.log.levels.WARN)
    return
  end

  conform.setup({
    formatters_by_ft = M.formatters_by_ft,

    -- 默认格式化选项
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true, -- 如果 LSP 支持格式化，也使用 LSP
    },

    -- 异步格式化
    format_after_save = {
      lsp_fallback = true,
    },

    -- 配置每个格式化器的选项
    formatters = {
      stylua = {
        prepend_args = { "--indent-width", "2", "--indent-type", "Spaces" },
      },
      prettier = {
        prepend_args = { "--single-quote", "--jsx-single-quote" },
      },
      prettierd = {
        prepend_args = { "--single-quote", "--jsx-single-quote" },
      },
      black = {
        prepend_args = { "--line-length", "88" },
      },
      isort = {
        prepend_args = { "--profile", "black" },
      },
      shfmt = {
        prepend_args = { "-i", "2" },
      },
      clang_format = {
        prepend_args = { "--style", "{BasedOnStyle: Google, IndentWidth: 2}" },
      },
    },

    -- 如果没有找到对应的格式化器，使用 LSP
    fallback_conform = function(bufnr)
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      for _, client in ipairs(clients) do
        if client.server_capabilities.documentFormattingProvider then
          vim.lsp.buf.format({ async = false, bufnr = bufnr })
          return true
        end
      end
      return false
    end,
  })

  -- 设置格式化快捷键
  vim.keymap.set({ "n", "v" }, "<leader>f", function()
    conform.format({ async = true, lsp_fallback = true })
  end, { desc = "使用 conform.nvim 格式化" })

  -- 查看当前文件的格式化器
  vim.keymap.set("n", "<leader>F", function()
    local ft = vim.bo.filetype
    local formatters = M.formatters_by_ft[ft] or {}
    local msg = "文件类型: " .. ft .. "\n可用的格式化器: "
    if #formatters > 0 then
      msg = msg .. table.concat(formatters, ", ")
    else
      msg = msg .. "无"
    end
    vim.notify(msg, vim.log.levels.INFO)
  end, { desc = "查看格式化器" })

  vim.notify("conform.nvim 已配置")
end

local function setup_global_keymaps()
  -- 设置全局按键映射
  vim.keymap.set("n", "gK", function()
    safe_lsp_action(vim.lsp.buf.hover, "没有活动的 LSP 客户端")
  end, { desc = "显示悬停文档" })

  vim.keymap.set("n", "gd", function()
    safe_lsp_action(vim.lsp.buf.definition, "没有活动的 LSP 客户端")
  end, { desc = "跳转到定义" })

  vim.keymap.set({ "n", "v" }, "<leader>ca", function()
    safe_lsp_action(vim.lsp.buf.code_action, "没有活动的 LSP 客户端")
  end, { desc = "代码操作" })

  vim.keymap.set("n", "<leader>rn", function()
    safe_lsp_action(vim.lsp.buf.rename, "没有活动的 LSP 客户端")
  end, { desc = "重命名符号" })

  vim.keymap.set({ "n", "v" }, "<leader>cf", function()
    -- 格式化（使用 conform.nvim）
    local conform_ok, conform = pcall(require, "conform")
    if conform_ok then
      conform.format({ async = true, lsp_fallback = true })
    else
      -- 回退到 LSP 格式化
      local bufnr = vim.api.nvim_get_current_buf()
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      local formatting_clients = {}
      for _, client in ipairs(clients) do
        if client.server_capabilities.documentFormattingProvider then
          table.insert(formatting_clients, client.name)
        end
      end
      if #formatting_clients > 0 then
        vim.lsp.buf.format({ async = true })
        vim.notify("正在格式化... (" .. table.concat(formatting_clients, ", ") .. ")", vim.log.levels.INFO)
      else
        vim.notify("没有找到可用的格式化器", vim.log.levels.WARN)
      end
    end
  end, { desc = "格式化文档" })

  -- 查看引用
  vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "查看引用" })
  -- 查看实现
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "查看实现" })
  -- 类型定义
  vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { desc = "跳转到类型定义" })
  -- 签名帮助
  vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "签名帮助" })
  -- 这些映射已在 setup_global_keymaps 中设置，避免重复
  -- vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
  -- vim.keymap.set("n", "gh", vim.lsp.buf.hover)
  vim.keymap.set("n", "g[", function()
    vim.diagnostic.goto_prev()
  end)
  vim.keymap.set("n", "g]", function()
    vim.diagnostic.goto_next()
  end)
  vim.keymap.set("n", "go", function()
    vim.diagnostic.open_float()
  end)
  vim.keymap.set("n", "<leader>q", function()
    vim.diagnostic.setloclist()
  end)
end

local function setup_diagnostics()
  -- 设置诊断
  vim.diagnostic.config({
    virtual_text = {
      prefix = "●",
      spacing = 2,
    },
    signs = true,
    underline = true,
    -- 在插入模式下也更新诊断
    update_in_insert = true,
    severity_sort = true,
    float = {
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
    -- 启用异步诊断
    virtual_lines = false,
  })

  -- 设置诊断符号
  local signs = {
    Error = "",
    Warn = "",
    Hint = "",
    Info = "",
  }

  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end
end

local function start_lsp_for_filetype(ft, bufnr)
  -- 启动文件类型的 LSP
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- 跳过不需要 LSP 检查的文件类型
  if M.skip_filetypes[ft] then
    return
  end

  -- 避免重复启动
  if vim.b[bufnr].lsp_started then
    return
  end

  -- 通知 LSP 语法检查开始（仅在调试模式下显示）
  if vim.g.lsp_debug then
    local current_time = os.date("%H:%M:%S")
    vim.notify("开始 LSP 语法检查: " .. ft .. " (" .. current_time .. ")", vim.log.levels.INFO)
  end

  local server_names = M.filetype_mappings[ft]
  if not server_names then
    return
  end

  local started_servers = {}
  for _, server_name in ipairs(server_names) do
    -- 检查服务器是否已附加到当前缓冲区
    local clients = vim.lsp.get_clients({ name = server_name, bufnr = bufnr })
    if #clients > 0 then
      -- 服务器已附加到当前缓冲区
      table.insert(started_servers, server_name)
    else
      -- 服务器未附加到当前缓冲区，尝试附加到已存在的客户端
      local all_clients = vim.lsp.get_clients({ name = server_name })
      local attached = false

      for _, client in ipairs(all_clients) do
        -- 检查文件类型是否匹配
        local should_attach = true
        if client.config and client.config.filetypes then
          should_attach = false
          for _, client_ft in ipairs(client.config.filetypes) do
            if client_ft == ft then
              should_attach = true
              break
            end
          end
        end

        if should_attach and not vim.lsp.buf_is_attached(bufnr, client.id) then
          vim.lsp.buf_attach_client(bufnr, client.id)
          attached = true
          if vim.g.lsp_debug then
            vim.notify("附加到已存在的 LSP 客户端: " .. server_name, vim.log.levels.INFO)
          end
        elseif vim.lsp.buf_is_attached(bufnr, client.id) then
          attached = true
        end
      end

      if attached then
        table.insert(started_servers, server_name)
      else
        -- 如果没有可用的客户端，尝试启动新的服务器
        -- 使用我们的配置来启动
        local success = M.start_server_with_config(server_name, bufnr)
        if success then
          table.insert(started_servers, server_name)
          if vim.g.lsp_debug then
            vim.notify("已启动 LSP 服务器: " .. server_name, vim.log.levels.INFO)
          end
        elseif vim.g.lsp_debug then
          vim.notify(
            "跳过 LSP " .. server_name .. ": 没有可用的客户端或文件类型不匹配",
            vim.log.levels.WARN
          )
        end
      end
    end
  end

  if #started_servers > 0 then
    vim.b[bufnr].lsp_started = true
    if vim.g.lsp_debug then
      local end_time = os.date("%H:%M:%S")
      vim.notify(
        "LSP 语法检查完成: " .. ft .. " (" .. end_time .. ")服务器: " .. table.concat(started_servers, ", "),
        vim.log.levels.INFO
      )
    end
  end
end

function M.setup()
  -- 主设置函数
  -- 设置诊断
  setup_diagnostics()

  -- 设置全局按键映射
  setup_global_keymaps()

  -- 设置 conform.nvim
  setup_conform()

  -- 使用 ftplugin autocmd 统一加载 LSP 配置
  -- 这会替代所有单独的 ftplugin 文件
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("LSPFileType", { clear = true }),
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

  -- 保存时自动格式化（使用 conform.nvim）
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("LSPAutoFormat", { clear = true }),
    callback = function(args)
      local bufnr = args.buf
      local ft = vim.bo[bufnr].filetype

      -- 跳过不需要格式化的文件类型
      if M.skip_filetypes[ft] then
        return
      end

      -- 检查是否有对应的格式化器
      local formatters = M.formatters_by_ft[ft] or M.formatters_by_ft["*"] or {}

      if #formatters > 0 and vim.g.auto_format ~= false then
        local conform_ok, conform = pcall(require, "conform")
        if conform_ok then
          -- 使用 conform.nvim 格式化
          local success = pcall(conform.format, {
            async = false,
            bufnr = bufnr,
            lsp_fallback = true,
            timeout_ms = 1000,
          })

          if not success then
            -- 如果 conform 格式化失败，尝试 LSP
            local clients = vim.lsp.get_clients({ bufnr = bufnr })
            for _, client in ipairs(clients) do
              if client.server_capabilities.documentFormattingProvider then
                pcall(vim.lsp.buf.format, { async = false, bufnr = bufnr })
                break
              end
            end
          end
        else
          -- 回退到 LSP 格式化
          local clients = vim.lsp.get_clients({ bufnr = bufnr })
          for _, client in ipairs(clients) do
            if client.server_capabilities.documentFormattingProvider then
              pcall(vim.lsp.buf.format, { async = false, bufnr = bufnr })
              break
            end
          end
        end
      end
    end,
  })

  -- 初始化 Mason
  M.setup_mason()

  vim.notify("LSP 和 conform.nvim 配置已加载")

  -- 清理可能存在的重复客户端
  vim.defer_fn(function()
    M.cleanup_duplicate_clients()
  end, 500)
end

function M.cleanup_duplicate_clients()
  -- 清理重复的 LSP 客户端，优先保留使用我们配置的客户端
  local all_clients = vim.lsp.get_clients()
  local clients_by_name = {}
  local removed = 0

  -- 按名称分组客户端
  for _, client in ipairs(all_clients) do
    if not clients_by_name[client.name] then
      clients_by_name[client.name] = {}
    end
    table.insert(clients_by_name[client.name], client)
  end

  -- 检查每个名称的客户端
  for name, client_list in pairs(clients_by_name) do
    if #client_list > 1 then
      if vim.g.lsp_debug then
        vim.notify("发现重复的 LSP 客户端: " .. name .. " (" .. #client_list .. " 个实例)")
      end

      -- 找出使用我们配置的客户端
      local our_config_clients = {}
      local default_config_clients = {}

      for _, client in ipairs(client_list) do
        -- 检查是否使用我们的配置（通过检查是否有我们的特定设置）
        local is_our_config = false
        if client.config and client.config.settings then
          -- 检查是否有我们配置的特定字段
          if name == "lua_ls" and client.config.settings.Lua then
            -- 检查是否有我们配置的全局变量
            if client.config.settings.Lua.diagnostics and client.config.settings.Lua.diagnostics.globals then
              is_our_config = true
            end
          elseif client.config.settings then
            -- 对于其他服务器，如果有 settings 就认为是我们的配置
            is_our_config = true
          end
        end

        if is_our_config then
          table.insert(our_config_clients, client)
        else
          table.insert(default_config_clients, client)
        end
      end

      -- 优先保留使用我们配置的客户端
      local clients_to_keep = {}
      if #our_config_clients > 0 then
        if vim.g.lsp_debug then
          vim.notify("  保留使用我们配置的客户端 (" .. #our_config_clients .. " 个)")
        end
        clients_to_keep = our_config_clients
      else
        if vim.g.lsp_debug then
          vim.notify("  没有找到使用我们配置的客户端，保留第一个默认配置客户端")
        end
        -- 保留第一个默认配置客户端
        table.insert(clients_to_keep, default_config_clients[1])
      end

      -- 停止不需要的客户端
      for _, client in ipairs(client_list) do
        local should_keep = false
        for _, keep_client in ipairs(clients_to_keep) do
          if client.id == keep_client.id then
            should_keep = true
            break
          end
        end

        if not should_keep then
          if vim.g.lsp_debug then
            vim.notify("  停止实例 ID: " .. client.id)
          end
          client:stop()
          removed = removed + 1
        end
      end
    end
  end

  if removed > 0 then
    if vim.g.lsp_debug then
      vim.notify("已停止 " .. removed .. " 个重复的 LSP 客户端实例")
    end
    vim.notify("已清理 " .. removed .. " 个重复的 LSP 客户端", vim.log.levels.INFO)
  elseif vim.g.lsp_debug then
    vim.notify("未发现重复的 LSP 客户端")
  end
end

function M.setup_mason()
  -- Mason 设置
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
        package_uninstalled = "✗",
      },
    },
  })

  -- 配置 mason-lspconfig
  local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
  if mason_lspconfig_ok then
    -- 定义处理器函数
    local function setup_server(server_name)
      -- 调试信息
      if vim.g.lsp_debug then
        vim.notify("[LSP] ========================================")
        vim.notify("[LSP] 开始配置服务器: " .. server_name)
        vim.notify("[LSP] ========================================")
      end

      local config = M.server_configs[server_name] or {}

      -- 调试信息：显示加载的配置
      if vim.g.lsp_debug then
        vim.notify("[LSP] 为服务器 " .. server_name .. " 加载配置:")
        vim.notify("  配置文件存在: " .. (next(config) ~= nil and "是" or "否"))
        if next(config) ~= nil then
          vim.notify("  设置字段: " .. (config.settings and "有" or "无"))
          vim.notify("  文件类型: " .. (config.filetypes and table.concat(config.filetypes, ", ") or "无"))
        end
      end

      -- 确保配置包含必要的字段
      local cmd = config.cmd or get_default_cmd(server_name)

      if not cmd then
        if vim.g.lsp_debug then
          vim.notify("跳过 LSP " .. server_name .. ": 未找到 cmd 配置", vim.log.levels.WARN)
        end
        return
      end

      -- 构建完整的配置
      local lsp_config = {
        name = server_name,
        cmd = cmd,
        settings = config.settings or {},
        on_attach = config.on_attach or function(client, bufnr)
          -- 默认的 on_attach 函数
          if client.server_capabilities.documentFormattingProvider then
            vim.api.nvim_buf_set_option(bufnr, "formatexpr", "v:lua.vim.lsp.formatexpr()")
          end

          -- 设置缓冲区本地按键映射
          local bufopts = { noremap = true, silent = true, buffer = bufnr }
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
          vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, bufopts)
          vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
          vim.keymap.set("n", "<leader>wl", function()
            vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, bufopts)
          vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, bufopts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, bufopts)
        end,
        capabilities = config.capabilities or vim.lsp.protocol.make_client_capabilities(),
        root_dir = config.root_dir,
        filetypes = config.filetypes,
        manual = true, -- 手动启动，避免自动启动
      }

      -- 调试信息：显示最终配置
      if vim.g.lsp_debug then
        vim.notify("[LSP] 最终配置 " .. server_name .. ":")
        vim.notify("  cmd: " .. vim.inspect(cmd))
        vim.notify("  设置字段数量: " .. (lsp_config.settings and #vim.tbl_keys(lsp_config.settings) or 0))
        if lsp_config.settings and server_name == "lua_ls" then
          vim.notify("  Lua 设置: " .. (lsp_config.settings.Lua and "有" or "无"))
        end
      end

      -- 根据配置决定使用哪种方式
      if M.config.use_lspconfig then
        -- 使用 nvim-lspconfig 配置服务器（只配置，不启动）
        local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
        if lspconfig_ok then
          -- 直接使用我们的配置，不合并默认配置
          -- 这样可以确保我们的配置完全生效

          -- 调试：打印我们的配置
          if vim.g.lsp_debug then
            vim.notify("[LSP] 准备配置服务器: " .. server_name)
            vim.notify("[LSP] 我们的配置:")
            vim.notify(vim.inspect(lsp_config))

            -- 检查现有的配置
            if lspconfig[server_name] and lspconfig[server_name].document_config then
              vim.notify("[LSP] 现有默认配置:")
              vim.notify(vim.inspect(lspconfig[server_name].document_config.default_config))
            end
          end

          -- 配置服务器但不启动
          lspconfig[server_name].setup(lsp_config)

          -- 验证配置是否已应用
          if vim.g.lsp_debug then
            vim.defer_fn(function()
              vim.notify("[LSP] 配置后验证:")
              local current_config = lspconfig[server_name].document_config.default_config
              vim.notify("  cmd: " .. vim.inspect(current_config.cmd))
              if current_config.settings and current_config.settings.Lua then
                vim.notify("  Lua 运行时路径: " .. (current_config.settings.Lua.runtime and "有" or "无"))
                vim.notify(
                  "  Lua 诊断全局变量数量: "
                    .. (
                      current_config.settings.Lua.diagnostics
                        and current_config.settings.Lua.diagnostics.globals
                        and #current_config.settings.Lua.diagnostics.globals
                      or 0
                    )
                )
              end
            end, 100)
          end

          if vim.g.lsp_debug then
            vim.notify("已配置 LSP 服务器: " .. server_name, vim.log.levels.INFO)
            vim.notify("[LSP] 服务器 " .. server_name .. " 配置完成（未启动）")
          end
        else
          -- 回退到 vim.lsp.start（但也不启动）
          if vim.g.lsp_debug then
            vim.notify("[LSP] 警告: nvim-lspconfig 不可用，使用 vim.lsp.start 配置 " .. server_name)
          end
          -- 只构建配置，不启动
          local client_id = vim.lsp.start(lsp_config)
          if client_id then
            -- 立即停止，因为我们只想要配置
            local client = vim.lsp.get_client_by_id(client_id)
            if client then
              client:stop()
            end
          end
        end
      else
        -- 使用 Neovim 0.12 的内置 LSP API
        -- 我们只需要存储配置，服务器会在需要时启动
        if vim.g.lsp_debug then
          vim.notify("[LSP] 使用 Neovim 内置 LSP API 配置 " .. server_name)
          vim.notify("[LSP] 配置已存储，服务器将在需要时启动")
        end

        -- 将配置存储到全局表，供 start_server_with_config 使用
        if not M._server_configs then
          M._server_configs = {}
        end
        M._server_configs[server_name] = lsp_config
      end
    end

    -- 禁用 mason-lspconfig 的自动配置，完全使用我们的配置系统
    -- 这样可以避免配置冲突和重复客户端问题
    mason_lspconfig.setup({
      -- 禁用自动安装，我们有自己的安装逻辑
      automatic_installation = false,

      -- 确保安装的服务器（仅用于显示，不自动安装）
      ensure_installed = {
        "lua_ls",
        "pyright",
        "ts_ls",
        "html",
        "cssls",
        "jsonls",
        "yamlls",
        "bashls",
        "clangd",
        "gopls",
        "rust_analyzer",
      },

      -- 配置处理器 - 只配置，不自动启动
      handlers = {
        -- 默认处理器，只配置不启动
        function(server_name)
          setup_server(server_name)
        end,

        -- 为 lua_ls 提供专门的处理器
        lua_ls = function()
          setup_server("lua_ls")
        end,
      },
    })
  end

  -- 安装推荐的 LSP 服务器和格式化工具
  vim.defer_fn(function()
    -- 尝试获取包列表，如果获取不到就更新
    local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
    if not mason_registry_ok or not mason_registry.get_package then
      vim.cmd("MasonUpdate")
    end

    -- 验证 LSP 配置（不启动服务器）
    M.setup_lsp_configs()

    M.ensure_lsp_servers()
    M.ensure_formatters()
  end, 1000)
end

function M.setup_lsp_configs()
  -- 只配置 LSP 服务器，不启动
  -- 在 Neovim 0.12+ 中，服务器应该按需启动

  if vim.g.lsp_debug then
    vim.notify("[LSP] 配置服务器设置（不启动）...")
  end

  -- 我们只需要确保配置存在，服务器会在需要时由 start_lsp_for_filetype 启动
  -- 这里不执行任何启动操作，只是验证配置

  local valid_configs = 0
  local invalid_configs = 0

  for server_name, _ in pairs(M.lsp_to_mason) do
    local config = M.server_configs[server_name] or {}
    local cmd = config.cmd or get_default_cmd(server_name)

    if cmd then
      valid_configs = valid_configs + 1
      if vim.g.lsp_debug then
        vim.notify("[LSP] 配置有效: " .. server_name)
      end
    else
      invalid_configs = invalid_configs + 1
      if vim.g.lsp_debug then
        vim.notify("[LSP] 配置无效: " .. server_name .. " (缺少 cmd)")
      end
    end
  end

  if vim.g.lsp_debug then
    vim.notify("[LSP] 配置验证完成: " .. valid_configs .. " 个有效, " .. invalid_configs .. " 个无效")
  end

  vim.notify("LSP 配置验证完成 (" .. valid_configs .. " 个有效配置)", vim.log.levels.INFO)
end

function M.reconfigure_servers()
  -- 强制重新配置所有服务器，确保使用我们的配置
  if vim.g.lsp_debug then
    vim.notify("[LSP] 开始重新配置所有服务器...")
  end

  -- 停止所有现有的客户端
  local all_clients = vim.lsp.get_clients()
  for _, client in ipairs(all_clients) do
    client:stop()
  end

  -- 清除所有缓冲区的标记
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    vim.b[bufnr].lsp_started = nil
  end

  -- 重新配置所有服务器
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if lspconfig_ok then
    for server_name, _ in pairs(M.lsp_to_mason) do
      local config = M.server_configs[server_name] or {}
      local cmd = config.cmd or get_default_cmd(server_name)

      if cmd then
        local lsp_config = {
          name = server_name,
          cmd = cmd,
          settings = config.settings or {},
          on_attach = config.on_attach or function(client, bufnr)
            -- 默认的 on_attach 函数
            if client.server_capabilities.documentFormattingProvider then
              vim.api.nvim_buf_set_option(bufnr, "formatexpr", "v:lua.vim.lsp.formatexpr()")
            end

            -- 设置缓冲区本地按键映射
            local bufopts = { noremap = true, silent = true, buffer = bufnr }
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
            vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
            vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, bufopts)
            vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
            vim.keymap.set("n", "<leader>wl", function()
              vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end, bufopts)
            vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, bufopts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
            vim.keymap.set("n", "<leader>f", function()
              vim.lsp.buf.format({ async = true })
            end, bufopts)
          end,
          capabilities = config.capabilities or vim.lsp.protocol.make_client_capabilities(),
          root_dir = config.root_dir,
          filetypes = config.filetypes,
          manual = true,
        }

        lspconfig[server_name].setup(lsp_config)

        if vim.g.lsp_debug then
          vim.notify("[LSP] 已重新配置服务器: " .. server_name)
        end
      end
    end
  end

  vim.notify("所有 LSP 服务器已重新配置", vim.log.levels.INFO)
end

function M.ensure_lsp_servers()
  -- 确保 LSP 服务器已安装
  local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_registry_ok then
    return
  end

  local installed = 0
  local to_install = {}

  for lsp_name, mason_name in pairs(M.lsp_to_mason) do
    local ok, pkg = pcall(mason_registry.get_package, mason_name)
    if ok and pkg:is_installed() then
      installed = installed + 1
    else
      table.insert(to_install, { lsp_name, mason_name })
    end
  end

  if #to_install > 0 then
    vim.notify(
      "有 " .. #to_install .. " 个 LSP 服务器需要安装，运行 :LspInstallMissing 安装",
      vim.log.levels.INFO
    )
    vim.cmd(":LspInstallMissing")
  else
    vim.notify("所有 LSP 服务器已安装 (" .. installed .. " 个)", vim.log.levels.INFO)
  end
end

function M.ensure_formatters()
  -- 确保格式化工具已安装
  local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_registry_ok then
    return
  end

  local installed = 0
  local to_install = {}
  local added = {} -- 用于避免重复添加

  -- 收集需要安装的格式化工具
  for _, formatters in pairs(M.formatters_by_ft) do
    for _, formatter in ipairs(formatters) do
      local mason_name = M.formatter_to_mason[formatter]
      if mason_name and not added[mason_name] then
        local ok, pkg = pcall(mason_registry.get_package, mason_name)
        if ok and pkg:is_installed() then
          installed = installed + 1
        elseif ok then
          added[mason_name] = true
          table.insert(to_install, { formatter, mason_name })
        end
      end
    end
  end

  if #to_install > 0 then
    vim.notify(
      "有 " .. #to_install .. " 个格式化工具需要安装，运行 :FormatterInstallMissing 安装",
      vim.log.levels.INFO
    )
    vim.cmd("FormatterInstallMissing")
  else
    vim.notify("所有格式化工具已安装 (" .. installed .. " 个)", vim.log.levels.INFO)
  end
end

vim.api.nvim_create_user_command("LspInstallMissing", function()
  -- 安装缺失的 LSP 服务器
  local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_registry_ok then
    vim.notify("无法访问 Mason 注册表", vim.log.levels.ERROR)
    return
  end

  local installed = 0
  for lsp_name, mason_name in pairs(M.lsp_to_mason) do
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

vim.api.nvim_create_user_command("FormatterInstallMissing", function()
  -- 安装缺失的格式化工具
  local mason_registry_ok, mason_registry = pcall(require, "mason-registry")
  if not mason_registry_ok then
    vim.notify("无法访问 Mason 注册表", vim.log.levels.ERROR)
    return
  end

  local installed = 0
  for formatter, mason_name in pairs(M.formatter_to_mason) do
    local ok, pkg = pcall(mason_registry.get_package, mason_name)
    if ok and not pkg:is_installed() then
      pkg:install()
      vim.notify("正在安装: " .. mason_name .. " (" .. formatter .. ")", vim.log.levels.INFO)
      installed = installed + 1
    end
  end

  if installed > 0 then
    vim.notify("已开始安装 " .. installed .. " 个格式化工具", vim.log.levels.INFO)
  else
    vim.notify("所有格式化工具已安装", vim.log.levels.INFO)
  end
end, { desc = "安装缺失的格式化工具" })

vim.api.nvim_create_user_command("LspStatus", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if #clients == 0 then
    vim.notify("当前缓冲区没有活动的 LSP 客户端")
  else
    vim.notify("当前缓冲区的 LSP 客户端:")
    for _, client in ipairs(clients) do
      vim.notify("  - " .. client.name)
      vim.notify("    格式化支持: " .. tostring(client.server_capabilities.documentFormattingProvider))
      vim.notify("    悬停支持: " .. tostring(client.server_capabilities.hoverProvider))
    end
  end

  vim.notify("文件类型: " .. vim.bo.filetype)

  local servers = M.filetype_mappings[vim.bo.filetype]
  if servers then
    vim.notify("配置的 LSP 服务器: " .. table.concat(servers, ", "))
  end

  -- 显示所有可用的 LSP 服务器
  local available_servers = M.get_available_servers()
  if #available_servers > 0 then
    table.sort(available_servers)
    vim.notify("可用的 LSP 服务器: " .. table.concat(available_servers, ", "))
  end

  -- 显示格式化器信息
  local conform_ok, _ = pcall(require, "conform")
  if conform_ok then
    local ft = vim.bo.filetype
    local formatters = M.formatters_by_ft[ft] or {}
    if #formatters > 0 then
      vim.notify("配置的格式化器: " .. table.concat(formatters, ", "))
    else
      vim.notify("配置的格式化器: 无")
    end
  end
end, { desc = "显示 LSP 状态" })

vim.api.nvim_create_user_command("LspClients", function()
  -- 显示所有 LSP 客户端的详细信息
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  vim.notify("=== LSP 客户端详细信息 ===")
  vim.notify("缓冲区: " .. bufnr)
  vim.notify("文件类型: " .. ft)
  vim.notify("")

  -- 当前缓冲区的客户端
  local buf_clients = vim.lsp.get_clients({ bufnr = bufnr })
  vim.notify("附加到当前缓冲区的客户端 (" .. #buf_clients .. " 个):")
  for _, client in ipairs(buf_clients) do
    vim.notify("  " .. client.name .. " (ID: " .. client.id .. ")")
    vim.notify("    配置文件: " .. (client.config and "是" or "否"))
    vim.notify(
      "    文件类型: "
        .. (client.config and client.config.filetypes and table.concat(client.config.filetypes, ", ") or "未知")
    )
    vim.notify("    根目录: " .. (client.config and client.config.root_dir or "无"))
  end

  vim.notify("")

  -- 所有客户端
  local all_clients = vim.lsp.get_clients()
  vim.notify("所有 LSP 客户端 (" .. #all_clients .. " 个):")

  local clients_by_name = {}
  for _, client in ipairs(all_clients) do
    if not clients_by_name[client.name] then
      clients_by_name[client.name] = {}
    end
    table.insert(clients_by_name[client.name], client)
  end

  for name, client_list in pairs(clients_by_name) do
    vim.notify("  " .. name .. ": " .. #client_list .. " 个实例")
    for _, client in ipairs(client_list) do
      vim.notify("    实例 ID: " .. client.id)

      -- 检查附加的缓冲区
      local attached_buffers = {}
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.lsp.buf_is_attached(buf, client.id) then
          table.insert(attached_buffers, buf)
        end
      end

      if #attached_buffers > 0 then
        vim.notify("    附加到缓冲区: " .. table.concat(attached_buffers, ", "))
      else
        vim.notify("    未附加到任何缓冲区")
      end
    end
  end

  vim.notify("")
  vim.notify("=== 结束 ===")
end, { desc = "显示所有 LSP 客户端的详细信息" })

vim.api.nvim_create_user_command("LspCleanup", function()
  -- 清理重复的 LSP 客户端
  local all_clients = vim.lsp.get_clients()
  local clients_by_name = {}
  local removed = 0

  -- 按名称分组客户端
  for _, client in ipairs(all_clients) do
    if not clients_by_name[client.name] then
      clients_by_name[client.name] = {}
    end
    table.insert(clients_by_name[client.name], client)
  end

  -- 检查每个名称的客户端
  for name, client_list in pairs(clients_by_name) do
    if #client_list > 1 then
      vim.notify("发现重复的 LSP 客户端: " .. name .. " (" .. #client_list .. " 个实例)")

      -- 保留第一个，停止其他的
      for i = 2, #client_list do
        local client = client_list[i]
        vim.notify("  停止实例 ID: " .. client.id)
        client:stop()
        removed = removed + 1
      end
    end
  end

  if removed > 0 then
    vim.notify("已停止 " .. removed .. " 个重复的 LSP 客户端实例")
    vim.notify("已清理 " .. removed .. " 个重复的 LSP 客户端", vim.log.levels.INFO)
  else
    vim.notify("未发现重复的 LSP 客户端")
    vim.notify("没有发现重复的 LSP 客户端", vim.log.levels.INFO)
  end
end, { desc = "清理重复的 LSP 客户端" })

vim.api.nvim_create_user_command("LspDebug", function()
  vim.g.lsp_debug = not vim.g.lsp_debug
  if vim.g.lsp_debug then
    vim.notify("LSP 调试模式已启用", vim.log.levels.INFO)
  else
    vim.notify("LSP 调试模式已禁用", vim.log.levels.INFO)
  end
end, { desc = "切换 LSP 调试模式" })

vim.api.nvim_create_user_command("LspListServers", function()
  -- 列出所有可用的 LSP 服务器
  local servers = M.get_available_servers()
  if #servers == 0 then
    vim.notify("没有找到可用的 LSP 服务器配置")
    return
  end

  table.sort(servers)
  vim.notify("可用的 LSP 服务器配置 (" .. #servers .. " 个):")
  for _, server in ipairs(servers) do
    local config = M.server_configs[server]
    local has_config = next(config) ~= nil
    vim.notify(string.format("  - %-20s %s", server, has_config and "✓ 有配置" or "✗ 无配置"))
  end
end, { desc = "列出所有可用的 LSP 服务器" })

vim.api.nvim_create_user_command("LspReload", function()
  -- 重新加载 LSP 配置
  vim.notify("重新加载 LSP 配置...", vim.log.levels.INFO)

  -- 停止所有 LSP 客户端（使用安全的方法）
  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    -- 在 Neovim 0.12 中，使用 client:stop() 来停止客户端
    client:stop()
  end

  -- 清除缓冲区标记
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    vim.b[bufnr].lsp_started = nil
  end

  -- 重新设置 LSP
  M.setup()

  vim.notify("LSP 配置已重新加载", vim.log.levels.INFO)
end, { desc = "重新加载 LSP 配置" })

-- LSP 调试函数
local function debug_lsp_loading()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  vim.notify("=== LSP 加载调试信息 ===")
  vim.notify("文件类型: " .. (ft or "无"))
  vim.notify("缓冲区: " .. bufnr)

  -- 检查是否已标记为已启动
  vim.notify("lsp_started 标记: " .. tostring(vim.b[bufnr].lsp_started))

  -- 检查文件类型映射
  local servers = M.filetype_mappings[ft]
  if servers then
    vim.notify("配置的服务器: " .. table.concat(servers, ", "))
  else
    vim.notify("配置的服务器: 无")
  end

  -- 检查当前缓冲区的 LSP 客户端
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  vim.notify("当前缓冲区的 LSP 客户端数量: " .. #clients)
  for _, client in ipairs(clients) do
    vim.notify("  - " .. client.name)
  end

  -- 检查所有 LSP 客户端
  local all_clients = vim.lsp.get_clients()
  vim.notify("所有 LSP 客户端数量: " .. #all_clients)
  for _, client in ipairs(all_clients) do
    vim.notify("  - " .. client.name .. " (id: " .. client.id .. ")")
  end

  -- 检查 lua_ls 是否在运行
  local lua_clients = vim.lsp.get_clients({ name = "lua_ls" })
  vim.notify("lua_ls 客户端数量: " .. #lua_clients)

  -- 检查 Mason 状态
  local mason_ok, _ = pcall(require, "mason-registry")
  vim.notify("Mason 注册表可用: " .. tostring(mason_ok))

  if mason_ok then
    local mason_registry = require("mason-registry")
    local ok, pkg = pcall(mason_registry.get_package, "lua-language-server")
    if ok then
      vim.notify("lua-language-server 包存在: 是")
      vim.notify("lua-language-server 已安装: " .. tostring(pkg:is_installed()))
    else
      vim.notify("lua-language-server 包存在: 否")
    end
  end

  vim.notify("=== 调试结束 ===")
end

vim.api.nvim_create_user_command("LspDebugLoad", debug_lsp_loading, { desc = "调试 LSP 加载流程" })

vim.api.nvim_create_user_command("LuaLSStatus", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  vim.notify("=== Lua Language Server 状态检查 ===")
  vim.notify("文件类型: " .. (ft or "无"))
  vim.notify("缓冲区: " .. bufnr)

  -- 检查 lua_ls 客户端
  local lua_clients = vim.lsp.get_clients({ name = "lua_ls", bufnr = bufnr })
  vim.notify("lua_ls 客户端数量 (当前缓冲区): " .. #lua_clients)

  if #lua_clients > 0 then
    local client = lua_clients[1]
    vim.notify("客户端 ID: " .. client.id)
    vim.notify("服务器能力:")
    vim.notify("  格式化: " .. tostring(client.server_capabilities.documentFormattingProvider))
    vim.notify("  悬停: " .. tostring(client.server_capabilities.hoverProvider))
    vim.notify("  定义: " .. tostring(client.server_capabilities.definitionProvider))

    -- 检查配置
    if client.config and client.config.settings then
      vim.notify("配置已加载: 是")
      if client.config.settings.Lua and client.config.settings.Lua.diagnostics then
        local globals = client.config.settings.Lua.diagnostics.globals
        if globals then
          vim.notify("定义的全局变量: " .. table.concat(globals, ", "))
        else
          vim.notify("定义的全局变量: 无")
        end
      else
        vim.notify("Lua 诊断配置: 无")
      end
    else
      vim.notify("配置已加载: 否")
    end
  else
    vim.notify("lua_ls 未附加到当前缓冲区")

    -- 检查是否在其他地方运行
    local all_lua_clients = vim.lsp.get_clients({ name = "lua_ls" })
    vim.notify("lua_ls 总客户端数量: " .. #all_lua_clients)

    if #all_lua_clients > 0 then
      vim.notify("lua_ls 正在运行但未附加到当前缓冲区")
      for _, client in ipairs(all_lua_clients) do
        vim.notify("  客户端 ID: " .. client.id)

        -- 检查客户端附加的缓冲区
        local attached_buffers = {}
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.lsp.buf_is_attached(buf, client.id) then
            table.insert(attached_buffers, buf)
          end
        end

        if #attached_buffers > 0 then
          vim.notify("  附加到缓冲区: " .. table.concat(attached_buffers, ", "))
        else
          vim.notify("  未附加到任何缓冲区")
        end
      end
    end
  end

  -- 检查 Mason 安装状态
  local mason_ok, mason_registry = pcall(require, "mason-registry")
  if mason_ok then
    local ok, pkg = pcall(mason_registry.get_package, "lua-language-server")
    if ok then
      vim.notify("Mason 包状态:")
      vim.notify("  包存在: 是")
      vim.notify("  已安装: " .. tostring(pkg:is_installed()))

      if pkg:is_installed() then
        -- 在较新版本的 Mason 中，使用 get_install_path 方法
        local install_dir
        if pkg.get_install_path then
          install_dir = pkg:get_install_path()
        elseif pkg.install_path then
          install_dir = pkg.install_path
        end
        vim.notify("  安装路径: " .. (install_dir or "未知"))
      end
    else
      vim.notify("Mason 包状态: lua-language-server 包不存在")
    end
  else
    vim.notify("Mason 注册表不可用")
  end

  vim.notify("=== 检查完成 ===")
end, { desc = "检查 Lua Language Server 状态" })

vim.api.nvim_create_user_command("TestLuaLS", function()
  -- 创建一个测试缓冲区来验证 lua_ls 是否正常工作
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(bufnr)

  -- 设置文件类型为 lua
  vim.api.nvim_buf_set_option(bufnr, "filetype", "lua")

  -- 写入测试代码
  local test_code = [[
-- 测试 vim 变量识别
local test_var = vim.api.nvim_get_current_buf()
vim.notify("当前缓冲区:", test_var)

-- 测试 gh 函数（如果存在）
if gh then
  vim.notify("gh 函数存在")
else
  vim.notify("gh 函数未定义")
end

-- 测试其他常用变量
local mode = vim.fn.mode()
vim.notify("当前模式:", mode)

-- 测试 require
local ok, result = pcall(require, "vim")
vim.notify("require vim:", ok, result)
]]

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(test_code, "\n"))

  vim.notify("测试缓冲区已创建 (缓冲区: " .. bufnr .. ")")
  vim.notify("文件类型已设置为: lua")
  vim.notify("测试代码已写入")
  vim.notify("")
  vim.notify("现在可以检查以下内容:")
  vim.notify("1. 运行 :LuaLSStatus 检查 lua_ls 状态")
  vim.notify("2. 检查代码中是否有错误提示")
  vim.notify("3. 尝试悬停 (gh) 查看文档")
  vim.notify("4. 尝试跳转到定义 (gd)")

  -- 自动启动 LSP
  vim.schedule(function()
    start_lsp_for_filetype("lua", bufnr)
  end)
end, { desc = "创建测试缓冲区验证 lua_ls 功能" })

vim.api.nvim_create_user_command("LspTestConfig", function()
  -- 测试 LSP 配置是否生效
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  vim.notify("=== LSP 配置测试 ===")
  vim.notify("当前缓冲区: " .. bufnr)
  vim.notify("文件类型: " .. ft)
  vim.notify("")

  -- 测试 lua_ls 配置
  vim.notify("1. 测试 lua_ls 配置:")
  local lua_config = M.server_configs["lua_ls"] or {}
  if next(lua_config) ~= nil then
    vim.notify("  ✓ 找到 lua_ls 配置")
    if lua_config.settings and lua_config.settings.Lua then
      vim.notify("  ✓ Lua 设置存在")
      if lua_config.settings.Lua.diagnostics and lua_config.settings.Lua.diagnostics.globals then
        vim.notify("  ✓ 全局变量配置: " .. table.concat(lua_config.settings.Lua.diagnostics.globals, ", "))
      else
        vim.notify("  ✗ 没有全局变量配置")
      end
    else
      vim.notify("  ✗ 没有 Lua 设置")
    end
  else
    vim.notify("  ✗ 没有找到 lua_ls 配置")
  end
  vim.notify("")

  -- 检查当前缓冲区的客户端
  vim.notify("2. 当前缓冲区的 LSP 客户端:")
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    vim.notify("  ✗ 没有活动的 LSP 客户端")
  else
    for _, client in ipairs(clients) do
      vim.notify("  ✓ " .. client.name .. " (ID: " .. client.id .. ")")

      -- 检查配置
      if client.config and client.config.settings then
        vim.notify("    配置已加载: 是")
        if client.name == "lua_ls" and client.config.settings.Lua then
          vim.notify("    Lua 设置: 有")
        end
      else
        vim.notify("    配置已加载: 否")
      end
    end
  end
  vim.notify("")

  -- 检查应该启动的服务器
  vim.notify("3. 应该为当前文件类型启动的服务器:")
  local expected_servers = M.filetype_mappings[ft]
  if expected_servers then
    vim.notify("  " .. table.concat(expected_servers, ", "))

    -- 检查每个服务器是否已配置
    for _, server_name in ipairs(expected_servers) do
      local config = M.server_configs[server_name] or {}
      if next(config) ~= nil then
        vim.notify("    ✓ " .. server_name .. " 已配置")
      else
        vim.notify("    ✗ " .. server_name .. " 未配置")
      end
    end
  else
    vim.notify("  ✗ 没有为 " .. ft .. " 配置的服务器")
  end
  vim.notify("")

  vim.notify("=== 测试完成 ===")
  vim.notify("")
  vim.notify("建议操作:")
  vim.notify("1. 运行 :LspReconfigure 强制重新配置")
  vim.notify("2. 运行 :LspCleanup 清理重复客户端")
  vim.notify("3. 重新打开当前文件")
end, { desc = "测试 LSP 配置是否生效" })

vim.api.nvim_create_user_command("LspTestFiletype", function()
  -- 测试文件类型过滤功能
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  vim.notify("=== 文件类型过滤测试 ===")
  vim.notify("当前缓冲区: " .. bufnr)
  vim.notify("文件类型: " .. ft)
  vim.notify("")

  -- 获取所有客户端
  local all_clients = vim.lsp.get_clients()
  vim.notify("所有 LSP 客户端 (" .. #all_clients .. " 个):")

  for _, client in ipairs(all_clients) do
    vim.notify("  " .. client.name .. " (ID: " .. client.id .. ")")

    -- 检查文件类型配置
    if client.config and client.config.filetypes then
      vim.notify("    配置文件类型: " .. table.concat(client.config.filetypes, ", "))

      -- 检查是否匹配当前文件类型
      local matches = false
      for _, client_ft in ipairs(client.config.filetypes) do
        if client_ft == ft then
          matches = true
          break
        end
      end

      if matches then
        vim.notify("    ✓ 匹配当前文件类型")
      else
        vim.notify("    ✗ 不匹配当前文件类型")
      end
    else
      vim.notify("    未配置文件类型")
    end

    -- 检查是否附加到当前缓冲区
    local is_attached = vim.lsp.buf_is_attached(bufnr, client.id)
    vim.notify("    附加到当前缓冲区: " .. (is_attached and "是" or "否"))
    vim.notify("")
  end

  -- 检查应该为当前文件类型启动的服务器
  local expected_servers = M.filetype_mappings[ft]
  if expected_servers then
    vim.notify("应该为 " .. ft .. " 启动的服务器: " .. table.concat(expected_servers, ", "))
  else
    vim.notify("没有为 " .. ft .. " 配置的服务器")
  end

  vim.notify("")
  vim.notify("=== 测试完成 ===")
  vim.notify("")
  vim.notify("建议:")
  vim.notify("1. 运行 :LspReload 重新加载配置")
  vim.notify("2. 运行 :LspCleanup 清理重复客户端")
  vim.notify("3. 重新打开文件测试")
end, { desc = "测试文件类型过滤功能" })

vim.api.nvim_create_user_command("LspReconfigure", function()
  -- 强制重新配置所有 LSP 服务器
  vim.notify("正在重新配置所有 LSP 服务器...", vim.log.levels.INFO)
  M.reconfigure_servers()
  vim.notify("LSP 服务器已重新配置，请重新打开文件", vim.log.levels.INFO)
end, { desc = "强制重新配置所有 LSP 服务器" })

vim.api.nvim_create_user_command("LspQuickFix", function()
  -- 快速修复：停止所有默认配置的客户端，只保留我们的配置
  vim.notify("=== LSP 快速修复 ===")
  vim.notify("停止所有默认配置的 LSP 客户端...")

  local all_clients = vim.lsp.get_clients()
  local stopped = 0

  for _, client in ipairs(all_clients) do
    -- 检查是否是默认配置（没有我们的特定设置）
    local is_default_config = true

    if client.config and client.config.settings then
      if client.name == "lua_ls" and client.config.settings.Lua then
        -- 检查是否有我们配置的全局变量
        if client.config.settings.Lua.diagnostics and client.config.settings.Lua.diagnostics.globals then
          is_default_config = false
        end
      elseif client.config.settings then
        -- 对于其他服务器，如果有 settings 就认为是我们的配置
        is_default_config = false
      end
    end

    if is_default_config then
      vim.notify("  停止默认配置客户端: " .. client.name .. " (ID: " .. client.id .. ")")
      client:stop()
      stopped = stopped + 1
    end
  end

  vim.notify("已停止 " .. stopped .. " 个默认配置的客户端")
  vim.notify("")
  vim.notify("现在重新启动 LSP 服务器...")

  -- 重新启动当前文件的 LSP
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  if ft and ft ~= "" then
    -- 清除缓冲区标记
    vim.b[bufnr].lsp_started = nil

    -- 重新启动 LSP
    vim.schedule(function()
      start_lsp_for_filetype(ft, bufnr)
    end)

    vim.notify("已为 " .. ft .. " 重新启动 LSP 服务器")
  end

  vim.notify("=== 快速修复完成 ===")
  vim.notify("LSP 重复问题已解决，现在应该只使用你的配置", vim.log.levels.INFO)
end, { desc = "快速修复 LSP 重复问题（停止所有默认配置）" })

vim.api.nvim_create_user_command("LspFixNow", function()
  -- 立即修复重复的 LSP 客户端
  vim.notify("=== 立即修复 LSP 重复问题 ===")

  -- 1. 清理重复客户端
  M.cleanup_duplicate_clients()

  -- 2. 重新附加到当前缓冲区
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype

  if ft and ft ~= "" then
    vim.notify("重新附加 LSP 客户端到当前缓冲区 (文件类型: " .. ft .. ")")

    local server_names = M.filetype_mappings[ft]
    if server_names then
      for _, server_name in ipairs(server_names) do
        local clients = vim.lsp.get_clients({ name = server_name })
        for _, client in ipairs(clients) do
          if not vim.lsp.buf_is_attached(bufnr, client.id) then
            -- 检查文件类型是否匹配
            local should_attach = true
            if client.config and client.config.filetypes then
              should_attach = false
              for _, client_ft in ipairs(client.config.filetypes) do
                if client_ft == ft then
                  should_attach = true
                  break
                end
              end
            end

            if should_attach then
              vim.lsp.buf_attach_client(bufnr, client.id)
              vim.notify("  附加 " .. server_name .. " (ID: " .. client.id .. ")")
            end
          end
        end
      end
    end

    -- 更新缓冲区标记
    vim.b[bufnr].lsp_started = true
  end

  vim.notify("=== 修复完成 ===")
  vim.notify("LSP 重复问题已修复", vim.log.levels.INFO)
end, { desc = "立即修复重复的 LSP 客户端" })

function M.start_server_with_config(server_name, bufnr)
  -- 使用我们的配置启动 LSP 服务器
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- 优先使用存储的配置（如果使用内置 API）
  local lsp_config
  if not M.config.use_lspconfig and M._server_configs and M._server_configs[server_name] then
    lsp_config = vim.deepcopy(M._server_configs[server_name])

    if vim.g.lsp_debug then
      vim.notify("[LSP] 使用存储的配置启动 " .. server_name)
    end
  else
    -- 回退到从配置文件加载
    local config = M.server_configs[server_name] or {}

    -- 确保配置包含必要的字段
    local cmd = config.cmd or get_default_cmd(server_name)

    if not cmd then
      if vim.g.lsp_debug then
        vim.notify("无法启动 LSP " .. server_name .. ": 未找到 cmd 配置", vim.log.levels.WARN)
      end
      return false
    end

    -- 构建完整的配置
    lsp_config = {
      name = server_name,
      cmd = cmd,
      settings = config.settings or {},
      on_attach = config.on_attach or function(client, bufnr)
        -- 默认的 on_attach 函数
        if client.server_capabilities.documentFormattingProvider then
          vim.api.nvim_buf_set_option(bufnr, "formatexpr", "v:lua.vim.lsp.formatexpr()")
        end

        -- 设置缓冲区本地按键映射
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, bufopts)
        vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, bufopts)
        vim.keymap.set("n", "<leader>wl", function()
          vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, bufopts)
        vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, bufopts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
        vim.keymap.set("n", "<leader>f", function()
          vim.lsp.buf.format({ async = true })
        end, bufopts)
      end,
      capabilities = config.capabilities or vim.lsp.protocol.make_client_capabilities(),
      root_dir = config.root_dir or vim.fn.getcwd(),
      filetypes = config.filetypes,
    }
  end

  -- 确保配置有必要的字段
  if not lsp_config.root_dir then
    lsp_config.root_dir = vim.fn.getcwd()
  end

  -- 调试信息
  if vim.g.lsp_debug then
    vim.notify("[LSP] 启动服务器 " .. server_name .. " 使用配置:")
    vim.notify("  cmd: " .. vim.inspect(lsp_config.cmd))
    if lsp_config.settings and lsp_config.settings.Lua then
      vim.notify("  Lua 运行时路径: " .. (lsp_config.settings.Lua.runtime and "有" or "无"))
      vim.notify(
        "  Lua 诊断全局变量数量: "
          .. (
            lsp_config.settings.Lua.diagnostics
              and lsp_config.settings.Lua.diagnostics.globals
              and #lsp_config.settings.Lua.diagnostics.globals
            or 0
          )
      )
    end
  end

  -- 使用 vim.lsp.start 启动服务器
  local client_id = vim.lsp.start(lsp_config)

  if client_id then
    -- 附加到缓冲区
    vim.lsp.buf_attach_client(bufnr, client_id)

    if vim.g.lsp_debug then
      vim.notify("[LSP] 服务器 " .. server_name .. " 已启动 (ID: " .. client_id .. ")")
    end

    return true
  else
    if vim.g.lsp_debug then
      vim.notify("无法启动 LSP 服务器: " .. server_name, vim.log.levels.ERROR)
    end
    return false
  end
end

-- 自动设置 LSP（如果从主配置调用）
if vim.g.lsp_auto_setup ~= false then
  vim.schedule(function()
    M.setup()
    vim.notify("LSP 配置已自动加载", vim.log.levels.INFO)
  end)
end

-- ============================================
-- 用户指南：解决 LSP 重复客户端问题
-- ============================================
--
-- 问题：LSP 启动了两个客户端，一个是默认配置，一个是你的配置
-- 原因：nvim-lspconfig 插件自动配置了默认设置
--
-- 解决方案：
-- 1. 我们已经注释掉了 nvim-lspconfig 插件的安装
-- 2. 现在完全使用 Neovim 0.12 的内置 LSP API
-- 3. 配置存储在 M._server_configs 表中，按需启动
--
-- 使用步骤：
-- 1. 运行 :LspQuickFix 停止所有默认配置的客户端
-- 2. 重新打开你的 Lua 文件
-- 3. LSP 应该只使用你的配置启动
--
-- 调试命令：
-- :LspDebug - 切换调试模式
-- :LspTestConfig - 测试配置是否生效
-- :LspStatus - 查看当前 LSP 状态
-- :LspClients - 查看所有客户端详细信息
--
-- 如果还有问题：
-- 1. 运行 :LspReconfigure 强制重新配置
-- 2. 运行 :LspCleanup 清理重复客户端
-- 3. 重新打开文件
--
-- 注意：现在配置中 use_lspconfig = false，完全使用内置 API
-- ============================================

return M
