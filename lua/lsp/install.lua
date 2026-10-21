-- ~/.config/nvim/lua/lsp/install.lua
-- 基于 Mason 的自动安装：LSP 服务器 + 格式化 / 检查工具。
--
-- 设计要点：
--   * 与 mason-lspconfig 的 ensure_installed 机制刻意分离（后者保持为空
--     {}），安装统一由本模块承担，避免两套逻辑重复安装与 checkhealth 告警。
--   * 数据来源单一：可用包清单来自 lsp/config.lua 的 lsp_to_mason /
--     formatter_to_mason / linter_to_mason（值为 mason 包名）。
--   * 全程 pcall 容错：注册表未就绪、离线、平台不支持等情形只告警不抛错，
--     绝不影响 Neovim 启动。
--   * headless（#nvim_list_uis() == 0）下 auto_install() 直接返回，避免
--     CI / 脚本环境触发下载。

local config = require("lsp.config")
local servers = require("lsp.servers")

local M = {}

--- 获取 mason-registry；未加载时返回 nil（不抛错）
---@return table|nil
local function get_registry()
  local ok, registry = pcall(require, "mason-registry")
  if not ok or type(registry) ~= "table" then
    return nil
  end
  return registry
end

--- 合并 formatter_to_mason 与 linter_to_mason 为单一映射
---@return table<string, string>
local function formatter_mapping()
  local map = {}
  for k, v in pairs(config.formatter_to_mason or {}) do
    map[k] = v
  end
  for k, v in pairs(config.linter_to_mason or {}) do
    map[k] = v
  end
  return map
end

--- Mason 包名 -> LSP 服务器名（反向映射，用于安装成功后即时启用）
---@return table<string, string>
local function package_to_server()
  local map = {}
  for server_name, mason_name in pairs(config.lsp_to_mason or {}) do
    if type(mason_name) == "string" then
      map[mason_name] = server_name
    end
  end
  return map
end

--- 让新安装的 LSP 服务器对「已打开且 filetype 命中」的 buffer 立即生效。
--- 实现：重新调用 vim.lsp.enable(name)。vim.lsp.enable 在 vim_did_enter 之后
--- 会对已有 buffer 重新执行 FileType 自动命令（doautoall），从而以正确的
--- filetypes / root_markers 启动客户端；已运行的同名客户端会被复用，不会重复。
---@param server_names string[]
local function attach_servers(server_names)
  for _, name in ipairs(server_names or {}) do
    if not config.options.external_lsp_servers[name] and servers.get(name) then
      pcall(vim.lsp.enable, name)
    end
  end
end

--- 订阅 Mason 安装成功事件：安装成功后即时启用新装的 LSP 服务器。
--- 幂等：mason-registry 未就绪时静默返回，下次调用（安装或启动时）会再尝试。
local function ensure_handler()
  if M._handler_registered then
    return
  end

  local registry = get_registry()
  if not registry or type(registry.on) ~= "function" then
    return
  end

  local pkg_to_server = package_to_server()

  local ok = pcall(function()
    registry:on("package:install:success", function(pkg)
      -- InstallRunner 触发时携带 (package, receipt)
      local mason_name = (type(pkg) == "table" and pkg.name) or nil
      local server_name = mason_name and pkg_to_server[mason_name]
      if not server_name then
        return
      end
      vim.schedule(function()
        attach_servers({ server_name })
      end)
    end)
  end)
  if ok then
    M._handler_registered = true
  end
end

--- 从「名称 -> mason 包名」映射中筛出尚未安装的包（按包名去重）
---@param mapping table<string, string>
---@return table[]  -- { { name = <mason 包名>, pkg = <Package> }, ... }
function M.missing_for(mapping)
  local registry = get_registry()
  if not registry then
    return {}
  end

  local missing, seen = {}, {}
  for _, mason_name in pairs(mapping or {}) do
    if type(mason_name) == "string" and not seen[mason_name] then
      seen[mason_name] = true

      local ok, pkg = pcall(registry.get_package, mason_name)
      if ok and pkg then
        local installed = false
        local installing = false
        pcall(function()
          installed = pkg:is_installed()
          installing = pkg:is_installing()
        end)
        if not installed and not installing then
          missing[#missing + 1] = { name = mason_name, pkg = pkg }
        end
      end
    end
  end
  return missing
end

--- 依次发起安装，返回成功发起安装的数量
---@param list table[]  -- M.missing_for(...) 的返回值
---@return integer
function M.install(list)
  ensure_handler()
  local count = 0
  for _, item in ipairs(list or {}) do
    if item and item.pkg then
      local ok = pcall(function()
        item.pkg:install()
      end)
      if ok then
        count = count + 1
      end
    end
  end
  return count
end

--- 便捷函数：安装某映射中缺失的包，返回发起安装的数量
---@param mapping table<string, string>
---@return integer
function M.install_missing(mapping)
  return M.install(M.missing_for(mapping))
end

--- 初始化（注册安装成功事件）。可在 mason-registry 就绪后重复调用。
function M.setup()
  ensure_handler()
end

--- 启动时自动安装缺失的 LSP 服务器 / 格式化工具。
function M.auto_install()
  -- headless（CI / 脚本）不触发下载
  if #vim.api.nvim_list_uis() == 0 then
    return
  end

  local opts = config.options.auto_install or {}
  if opts.servers == false and opts.formatters == false then
    return
  end

  local registry = get_registry()
  if not registry or type(registry.refresh) ~= "function" then
    vim.notify("[LSP] Mason 注册表不可用，跳过自动安装", vim.log.levels.WARN)
    return
  end

  ensure_handler()

  local function run(success)
    if not success then
      vim.notify("[LSP] Mason 注册表刷新失败（可能离线），跳过自动安装", vim.log.levels.WARN)
      return
    end

    local n_servers, n_tools = 0, 0
    if opts.servers ~= false then
      n_servers = M.install_missing(config.lsp_to_mason)
    end
    if opts.formatters ~= false then
      n_tools = M.install_missing(formatter_mapping())
    end

    if opts.notify ~= false and (n_servers + n_tools) > 0 then
      vim.notify(
        ("[LSP] 已开始自动安装 %d 个 LSP 服务器 / %d 个格式化工具"):format(n_servers, n_tools),
        vim.log.levels.INFO
      )
    end
  end

  local ok = pcall(function()
    registry.refresh(function(success)
      -- refresh 可能同步回调，统一调度到主循环，避免在 fast context 中安装
      vim.schedule(function()
        pcall(run, success)
      end)
    end)
  end)
  if not ok then
    vim.notify("[LSP] 自动安装初始化失败（已忽略）", vim.log.levels.WARN)
  end
end

return M
