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
  gh("neovim/nvim-lspconfig"), -- 虽然0.12有内置lsp，但这个插件提供更好配置
  -- Mason 和相关插件
  gh("williamboman/mason.nvim"),
  gh("williamboman/mason-lspconfig.nvim"),
  -- Formatter & Linter
  gh("stevearc/conform.nvim"),
})

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
  javascript = { "tsserver", "html", "cssls" },
  typescript = { "tsserver", "html", "cssls" },
  javascriptreact = { "tsserver", "html", "cssls" },
  typescriptreact = { "tsserver", "html", "cssls" },
  html = { "html", "cssls", "tsserver" },
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
  lua = { "lua_ls", "html" },
  python = { "pyright", "html", "cssls", "tsserver" },
  sh = { "bashls" },
  zsh = { "bashls" },
  bash = { "bashls" },
}

M.lsp_to_mason = {
  -- LSP 服务器到 Mason 包名的映射
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

local function load_server_config(server_name)
  -- 动态加载 LSP 服务器配置
  local ok, config = pcall(require, "lsp.configs." .. server_name)
  if ok then
    return config
  end
  return {}
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
        if client.supports_method("textDocument/formatting") then
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
        if client.supports_method("textDocument/formatting") then
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
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
  vim.keymap.set("n", "gh", vim.lsp.buf.hover)
  vim.keymap.set("n", "g[", vim.diagnostic.goto_prev)
  vim.keymap.set("n", "g]", vim.diagnostic.goto_next)
  vim.keymap.set("n", "go", vim.diagnostic.open_float)
  vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)
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

  -- 避免重复启动
  if vim.b[bufnr].lsp_started then
    return
  end

  local server_names = M.filetype_mappings[ft]
  if not server_names then
    return
  end

  -- 启动每个 LSP 服务器
  for _, server_name in ipairs(server_names) do
    local config = M.server_configs[server_name] or {}

    -- 使用 pcall 安全地启动 LSP
    local success, err = pcall(vim.lsp.config, server_name, config)
    if not success then
      vim.notify("配置 LSP " .. server_name .. " 失败: " .. tostring(err), vim.log.levels.WARN)
    end

    success, err = pcall(vim.lsp.enable, server_name)
    if success then
      vim.b[bufnr].lsp_started = true
    else
      vim.notify("启动 LSP " .. server_name .. " 失败: " .. tostring(err), vim.log.levels.ERROR)
    end
  end

  if vim.b[bufnr].lsp_started then
    vim.notify("LSP: " .. table.concat(server_names, ", ") .. " 已启用", vim.log.levels.INFO)
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
              if client.supports_method("textDocument/formatting") then
                pcall(vim.lsp.buf.format, { async = false, bufnr = bufnr })
                break
              end
            end
          end
        else
          -- 回退到 LSP 格式化
          local clients = vim.lsp.get_clients({ bufnr = bufnr })
          for _, client in ipairs(clients) do
            if client.supports_method("textDocument/formatting") then
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

  -- 安装推荐的 LSP 服务器和格式化工具
  vim.defer_fn(function()
    M.ensure_lsp_servers()
    M.ensure_formatters()
  end, 1000)
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

  local servers = M.filetype_mappings[vim.bo.filetype]
  if servers then
    print("配置的 LSP 服务器: " .. table.concat(servers, ", "))
  end

  -- 显示所有可用的 LSP 服务器
  local available_servers = M.get_available_servers()
  if #available_servers > 0 then
    table.sort(available_servers)
    print("可用的 LSP 服务器: " .. table.concat(available_servers, ", "))
  end

  -- 显示格式化器信息
  local conform_ok, _ = pcall(require, "conform")
  if conform_ok then
    local ft = vim.bo.filetype
    local formatters = M.formatters_by_ft[ft] or {}
    if #formatters > 0 then
      print("配置的格式化器: " .. table.concat(formatters, ", "))
    else
      print("配置的格式化器: 无")
    end
  end
end, { desc = "显示 LSP 状态" })

vim.api.nvim_create_user_command("LspListServers", function()
  -- 列出所有可用的 LSP 服务器
  local servers = M.get_available_servers()
  if #servers == 0 then
    print("没有找到可用的 LSP 服务器配置")
    return
  end

  table.sort(servers)
  print("可用的 LSP 服务器配置 (" .. #servers .. " 个):")
  for _, server in ipairs(servers) do
    local config = M.server_configs[server]
    local has_config = next(config) ~= nil
    print(string.format("  - %-20s %s", server, has_config and "✓ 有配置" or "✗ 无配置"))
  end
end, { desc = "列出所有可用的 LSP 服务器" })

return M
