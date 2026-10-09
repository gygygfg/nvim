-- ~/.config/nvim/lua/lsp/init.lua
-- LSP 入口：基于 Neovim 0.12 内置 LSP API（vim.lsp.config + vim.lsp.enable）。
--
-- 职责划分：
--   * lsp/config.lua     —— 静态数据（filetype_mappings / formatters_by_ft / …）
--   * lsp/servers.lua    —— 加载 lsp/configs/<name>.lua、注册、统一 enable
--   * lsp/memory.lua     —— 动态内存限制（作为 settings 注入）
--   * lsp/format.lua     —— conform.nvim 唯一配置源
--   * lsp/keymaps.lua    —— LSP 键位（含 skip 守卫）唯一来源
--   * 本文件             —— 诊断符号、setup 编排、常用用户命令

local M = {}

local config = require("lsp.config")
local servers = require("lsp.servers")
local memory = require("lsp.memory")

-- 防止重复加载
if M._loaded then
  return M
end
M._loaded = true

vim.pack.add({
  -- LSP 相关
  gh("j-hui/fidget.nvim"),
  gh("stevearc/dressing.nvim"),
  gh("folke/trouble.nvim"),
  gh("folke/which-key.nvim"),
  -- Mason
  gh("williamboman/mason.nvim"),
  gh("williamboman/mason-lspconfig.nvim"),
  -- Formatter
  gh("stevearc/conform.nvim"),
})

-- ============================================
-- 诊断
-- ============================================

local function setup_diagnostics()
  vim.diagnostic.config({
    virtual_text = {
      prefix = "●",
      spacing = 2,
    },
    signs = true,
    underline = true,
    update_in_insert = true,
    severity_sort = true,
    float = {
      border = "rounded",
      source = true,
      header = "",
      prefix = "",
    },
    virtual_lines = false,
  })

  -- 诊断符号
  local signs = {
    Error = "\238\170\135",
    Warn = "\238\169\172",
    Hint = "\238\169\161",
    Info = "\238\169\180",
  }

  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end
end

-- ============================================
-- Mason
-- ============================================

function M.setup_mason()
  local mason_ok, mason = pcall(require, "mason")
  if not mason_ok then
    vim.notify("[LSP] Mason 插件未加载", vim.log.levels.WARN)
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

  local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
  if mason_lspconfig_ok then
    -- mason-lspconfig v2：不再支持 handlers / automatic_installation。
    -- automatic_enable = false —— 由本模块的 servers.enable_all() 统一启用，
    -- 避免 mason 去 enable 没有配置的包（如 stylua），从而消除 checkhealth 告警。
    mason_lspconfig.setup({
      automatic_enable = false,
      ensure_installed = {},
    })
  end
end

-- ============================================
-- 主设置
-- ============================================

function M.setup()
  if M._setup_called then
    vim.notify("[LSP] 警告: setup() 已被调用过，跳过重复执行", vim.log.levels.WARN)
    return
  end
  M._setup_called = true

  setup_diagnostics()

  -- 注册并启用服务器（Neovim 0.12 原生机制）
  servers.register_all()
  servers.enable_all()

  require("lsp.keymaps").setup()
  require("lsp.format").setup()

  M.setup_mason()
end

-- 插件加载完成后重新烘焙 capabilities。
-- 说明：require("lsp").setup() 早于 plugins-manager 执行，此刻 cmp_nvim_lsp
-- 尚未加载，capabilities 只能回退到默认能力。插件加载完成后由主 init.lua
-- 调用本函数，用 cmp 的能力重新注册（vim.lsp.config 会失效缓存的
-- resolved_config，后续 FileType 即以新能力启动客户端）。
function M.refresh()
  servers.refresh()
end

-- ============================================
-- 用户命令
-- ============================================

local function ensure_mason_registry()
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    vim.notify("[LSP] 无法访问 Mason 注册表", vim.log.levels.ERROR)
    return nil
  end
  return registry
end

vim.api.nvim_create_user_command("LspInstallMissing", function()
  local registry = ensure_mason_registry()
  if not registry then
    return
  end

  local count = 0
  for _, mason_name in pairs(config.lsp_to_mason) do
    local ok, pkg = pcall(registry.get_package, mason_name)
    if ok and not pkg:is_installed() then
      pkg:install()
      count = count + 1
    end
  end
  vim.notify(
    count > 0 and ("[LSP] 已开始安装 " .. count .. " 个 LSP 服务器") or "[LSP] 所有 LSP 服务器已安装",
    vim.log.levels.INFO
  )
end, { desc = "安装缺失的 LSP 服务器" })

vim.api.nvim_create_user_command("FormatterInstallMissing", function()
  local registry = ensure_mason_registry()
  if not registry then
    return
  end

  local seen, count = {}, 0
  for _, mason_name in pairs(config.formatter_to_mason) do
    if not seen[mason_name] then
      seen[mason_name] = true
      local ok, pkg = pcall(registry.get_package, mason_name)
      if ok and not pkg:is_installed() then
        pkg:install()
        count = count + 1
      end
    end
  end
  vim.notify(
    count > 0 and ("[LSP] 已开始安装 " .. count .. " 个格式化工具") or "[LSP] 所有格式化工具已安装",
    vim.log.levels.INFO
  )
end, { desc = "安装缺失的格式化工具" })

vim.api.nvim_create_user_command("LspStatus", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  local lines = { "文件类型: " .. (ft ~= "" and ft or "(无)") }

  if #clients == 0 then
    lines[#lines + 1] = "当前缓冲区无活动 LSP 客户端"
  else
    lines[#lines + 1] = "当前缓冲区 LSP 客户端:"
    for _, client in ipairs(clients) do
      lines[#lines + 1] = ("  - %s (id=%d)"):format(client.name, client.id)
    end
  end

  local mapped = config.filetype_mappings[ft]
  if mapped then
    lines[#lines + 1] = "映射的服务器: " .. table.concat(mapped, ", ")
  end

  local formatters = config.formatters_by_ft[ft] or {}
  lines[#lines + 1] = "格式化器: " .. (#formatters > 0 and table.concat(formatters, ", ") or "无")

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, { desc = "显示当前缓冲区 LSP 状态" })

vim.api.nvim_create_user_command("LspClients", function()
  local all = vim.lsp.get_clients()
  local lines = { ("所有 LSP 客户端 (%d 个):"):format(#all) }
  for _, client in ipairs(all) do
    local attached = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.lsp.buf_is_attached(buf, client.id) then
        attached[#attached + 1] = buf
      end
    end
    lines[#lines + 1] = ("  %s (id=%d) root=%s bufs=[%s]"):format(
      client.name,
      client.id,
      tostring(client.config and client.config.root_dir or "-"),
      table.concat(attached, ",")
    )
  end
  print(table.concat(lines, "\n"))
end, { desc = "显示所有 LSP 客户端" })

vim.api.nvim_create_user_command("LspListServers", function()
  local lines = { "白名单服务器:" }
  for _, name in ipairs(servers.whitelist()) do
    local external = config.options.external_lsp_servers[name] and " (由外部插件托管)" or ""
    local cfg = servers.get(name)
    lines[#lines + 1] = ("  - %-18s %s%s"):format(name, cfg and "✓" or "✗", external)
  end
  print(table.concat(lines, "\n"))
end, { desc = "列出白名单中的 LSP 服务器" })

vim.api.nvim_create_user_command("LspDebug", function()
  vim.g.lsp_debug = not vim.g.lsp_debug
  vim.notify("[LSP] 调试模式: " .. (vim.g.lsp_debug and "开" or "关"), vim.log.levels.INFO)
end, { desc = "切换 LSP 调试模式" })

local function stop_all_clients()
  for _, client in ipairs(vim.lsp.get_clients()) do
    pcall(vim.lsp.stop_client, client.id)
  end
end

vim.api.nvim_create_user_command("LspReload", function()
  vim.notify("[LSP] 重新加载 LSP 配置...", vim.log.levels.INFO)
  stop_all_clients()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].lsp_started = nil
    end
  end
  servers.register_all()
  servers.enable_all()
  vim.notify("[LSP] LSP 配置已重新加载", vim.log.levels.INFO)
end, { desc = "重新加载 LSP 配置" })

vim.api.nvim_create_user_command("LspRestartAll", function()
  vim.notify("[LSP] 重启所有 LSP 客户端...", vim.log.levels.INFO)
  stop_all_clients()

  -- 重启 Godot LSP 后台服务（若处于 Godot 项目）
  local godot_ok, godot = pcall(require, "plugins.godot")
  local is_godot = godot_ok and godot.is_godot_project and godot.is_godot_project()
  if is_godot then
    if godot.stop_godot_lsp_server then
      godot.stop_godot_lsp_server()
    end
    if godot.reset_loaded then
      godot.reset_loaded()
    end
  end

  vim.defer_fn(function()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.b[bufnr].lsp_started = nil
      end
    end

    if is_godot then
      local g_ok, g = pcall(require, "plugins.godot")
      if g_ok and g.start_godot_lsp_server then
        g.start_godot_lsp_server()
      end
    end

    servers.register_all()
    servers.enable_all()
    vim.notify("[LSP] 重启完成", vim.log.levels.INFO)
  end, 1000)
end, { desc = "重启所有 LSP 客户端" })

-- 暴露给外部模块（如 plugins/godot.lua）
M.servers = servers
M.memory = memory

return M
