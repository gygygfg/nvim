-- ~/.config/nvim/lua/lsp/init.lua
-- LSP 入口：装配子模块、注册服务器、按需启动
-- 子模块：
--   lsp.config   —— 静态数据（文件类型映射、格式化器、跳过类型等）
--   lsp.memory   —— 动态内存限制与启动前并发检查
--   lsp.servers  —— 加载 configs/、注册到内置 API、按需启动
--   lsp.keymaps  —— 缓冲区级与诊断键位
--   lsp.format   —— 唯一的 conform.nvim 配置

local M = {}

local config = require("lsp.config")
local memory = require("lsp.memory")
local servers = require("lsp.servers")

-- 对外暴露（兼容历史引用）
M.options = config.options
M.config = config.options
M.filetype_mappings = config.filetype_mappings
M.formatters_by_ft = config.formatters_by_ft

-- 兼容旧接口：godot 等插件通过这些名字动态注册配置 / 触发启动
M._server_configs = servers._server_configs
M.start_lsp_for_filetype = servers.start_for_filetype

-- 依赖插件（通过 vim.pack 安装，不在此处加载）
vim.pack.add({
  gh("j-hui/fidget.nvim"),
  gh("stevearc/dressing.nvim"),
  gh("folke/trouble.nvim"),
  gh("folke/which-key.nvim"),
  gh("williamboman/mason.nvim"),
  gh("williamboman/mason-lspconfig.nvim"),
  gh("stevearc/conform.nvim"),
})

-- 诊断显示（全项目唯一一处 vim.diagnostic.config）
local function setup_diagnostics()
  vim.diagnostic.config({
    virtual_text = { prefix = "●", spacing = 2, source = "if_many" },
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded", source = true, header = "", prefix = "" },
  })
end

-- Mason：仅用于安装 LSP / 格式化工具，不自动配置服务器

-- GitHub Release 资产下载镜像（对应 mason 的 github.download_url_template）
-- 占位符顺序：1=仓库(owner/repo) 2=版本(vX.Y.Z) 3=资产文件名
local MASON_GITHUB_MIRROR = "https://ghfast.top/https://github.com/%s/releases/download/%s/%s"

-- 以下主机直连，不走本地代理（127.0.0.1:7890）
-- 注意：download.eclipse.org（jdtls 包源）直连只有 ~60KB/s，必须走代理，
--       不要加入本列表，否则 jdtls 安装会长时间卡住。
local MASON_DIRECT_HOSTS = {
  "ghfast.top",        -- GitHub Release 镜像（直连更快）
  "projectlombok.org", -- lombok.jar
}

-- 把直连主机并入 no_proxy，供 mason 内部调用的 curl/wget 使用
local function add_no_proxy(hosts)
  local merged = {}
  local current = (vim.env.no_proxy or "") .. "," .. (vim.env.NO_PROXY or "")
  for h in current:gmatch("[^,%s]+") do
    merged[h] = true
  end
  for _, h in ipairs(hosts) do
    merged[h] = true
  end
  local list = table.concat(vim.tbl_keys(merged), ",")
  vim.env.no_proxy = list
  vim.env.NO_PROXY = list
end

local function setup_mason()
  add_no_proxy(MASON_DIRECT_HOSTS)

  local ok, mason = pcall(require, "mason")
  if ok then
    mason.setup({
      ui = { border = "rounded" },
      github = { download_url_template = MASON_GITHUB_MIRROR },
    })
  end
  local ok2, mason_lspconfig = pcall(require, "mason-lspconfig")
  if ok2 then
    mason_lspconfig.setup({ automatic_installation = false })
  end
end

-- 轻量 UI：进度、按键提示、诊断面板
local function setup_ui()
  local ok, fidget = pcall(require, "fidget")
  if ok then
    fidget.setup({})
  end

  local ok2, which_key = pcall(require, "which-key")
  if ok2 then
    which_key.setup({})
  end

  vim.keymap.set("n", "<leader>xx", function()
    local ok3, trouble = pcall(require, "trouble")
    if ok3 then
      trouble.toggle("diagnostics")
    end
  end, { noremap = true, silent = true, desc = "诊断面板 (Trouble)" })
end

-- 安装缺失的 Mason 包
-- quiet = true 时，若没有缺失则静默返回（用于启动时自动补装）
local function install_missing(map, kind, quiet)
  local registry_ok, registry = pcall(require, "mason-registry")
  if not registry_ok then
    if not quiet then
      vim.notify("[LSP] mason-registry 未加载", vim.log.levels.WARN)
    end
    return
  end

  local missing = {}
  for _, pkg_name in pairs(map) do
    local ok, pkg = pcall(registry.get_package, pkg_name)
    if ok and not pkg:is_installed() and not pkg:is_installing() then
      missing[#missing + 1] = pkg_name
    end
  end

  if #missing == 0 then
    if not quiet then
      vim.notify("[LSP] 所有 " .. kind .. " 已安装", vim.log.levels.INFO)
    end
    return
  end

  for _, pkg_name in ipairs(missing) do
    local ok, pkg = pcall(registry.get_package, pkg_name)
    if ok then
      pkg:install()
    end
  end
  vim.notify("[LSP] 开始安装 " .. #missing .. " 个缺失的 " .. kind, vim.log.levels.INFO)
end

-- 启动时自动补装缺失的 LSP 服务器与格式化工具
local function auto_install_missing()
  install_missing(config.lsp_to_mason, "LSP 服务器", true)
  install_missing(config.formatter_to_mason, "格式化工具", true)
  install_missing(config.linter_to_mason, "检查工具", true)
end

-- 用户命令
local function setup_commands()
  vim.api.nvim_create_user_command("LspInstallMissing", function()
    install_missing(config.lsp_to_mason, "LSP 服务器")
    install_missing(config.formatter_to_mason, "格式化工具")
    install_missing(config.linter_to_mason, "检查工具")
  end, { desc = "安装缺失的 LSP 服务器与格式化工具" })

  vim.api.nvim_create_user_command("LspRestart", function()
    for _, client in ipairs(vim.lsp.get_clients()) do
      client:stop()
    end
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) then
        vim.b[bufnr].lsp_started = nil
        servers.start_for_filetype(vim.bo[bufnr].filetype, bufnr)
      end
    end
    vim.notify("[LSP] 已重启所有 LSP 客户端", vim.log.levels.INFO)
  end, { desc = "重启所有 LSP 客户端" })

  vim.api.nvim_create_user_command("LspMemoryStatus", function()
    local limits = memory.get_limits()
    vim.notify(
      string.format(
        "[LSP] 内存限制: 并发客户端=%d, 单客户端=%dMB, workspace文件=%d, lua_items=%d",
        limits.max_concurrent_clients,
        limits.max_memory_per_client,
        limits.max_workspace_files,
        limits.lua_max_items
      ),
      vim.log.levels.INFO
    )
  end, { desc = "显示当前 LSP 内存限制" })

  vim.api.nvim_create_user_command("LspForceMemoryLimit", function()
    servers.register_all()
    vim.notify("[LSP] 已按当前动态限制重新注册服务器配置（重启客户端后生效）", vim.log.levels.INFO)
  end, { desc = "强制应用内存限制到所有服务器" })
end

function M.setup()
  -- 防止重复设置
  if M._setup_called then
    return
  end
  M._setup_called = true

  require("lsp.keymaps").setup()
  require("lsp.format").setup()
  setup_diagnostics()
  setup_ui()
  setup_mason()
  setup_commands()

  -- 所有插件加载完成后再注册（确保 cmp_nvim_lsp 已就绪，能力注入完整）
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("LspRegister", { clear = true }),
    once = true,
    callback = function()
      servers.register_all()

      -- 所有插件就绪后，延迟自动补装缺失的 LSP / 格式化工具
      vim.defer_fn(auto_install_missing, 1000)
    end,
  })

  -- 按文件类型启动（白名单见 lsp.config.filetype_mappings）
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("LspStart", { clear = true }),
    callback = function(args)
      vim.schedule(function()
        servers.start_for_filetype(vim.bo[args.buf].filetype, args.buf)
      end)
    end,
  })

  -- 为启动前已打开的缓冲区补启动一次
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype ~= "" then
      servers.start_for_filetype(vim.bo[bufnr].filetype, bufnr)
    end
  end
end

return M
