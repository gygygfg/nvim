-- ~/.config/nvim/lua/lsp/servers.lua
-- LSP 服务器：加载 configs/ 配置、注册到内置 API、按需启动

local config = require("lsp.config")
local memory = require("lsp.memory")

local M = {}

-- 基础配置缓存（不含 capabilities，capabilities 在启动时惰性解析）
local built = {}

-- 运行时注册的服务器配置（如 godotdev 动态注入的 godot_editor）
M._server_configs = {}

-- 读取单个服务器配置（来自 lua/lsp/configs/<name>.lua）
local function load_config_file(server_name)
  local ok, mod = pcall(require, "lsp.configs." .. server_name)
  if ok and type(mod) == "table" then
    return mod
  end
  return {}
end

-- 默认客户端能力：优先使用 cmp_nvim_lsp（启用 snippet / SignatureHelp 等补全能力）
-- 注意：必须在启动/注册时调用，以确保 cmp 插件已就绪
local function default_capabilities()
  local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if ok and cmp_lsp.default_capabilities then
    return cmp_lsp.default_capabilities()
  end
  return vim.lsp.protocol.make_client_capabilities()
end

-- 合并默认能力与 server 自定义能力（server 配置优先）
local function with_caps(cfg)
  local c = memory.copy(cfg)
  c.capabilities = vim.tbl_deep_extend("force", default_capabilities(), cfg.capabilities or {})
  return c
end

-- 列出 lua/lsp/configs 下所有可用服务器名
function M.available()
  local dir = vim.fn.stdpath("config") .. "/lua/lsp/configs"
  local servers = {}
  local handle = vim.uv.fs_scandir(dir)
  if not handle then
    return servers
  end
  while true do
    local name, kind = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if kind == "file" and name:match("%.lua$") then
      servers[#servers + 1] = name:gsub("%.lua$", "")
    end
  end
  return servers
end

-- 构建基础配置（保留配置文件全部字段，不含 capabilities）
local function base_config(server_name)
  if built[server_name] then
    return built[server_name]
  end

  local cfg = memory.copy(load_config_file(server_name))
  cfg.name = server_name
  cfg.cmd = cfg.cmd or config.default_cmds[server_name]

  if not cfg.cmd then
    return nil
  end

  cfg.settings = cfg.settings or {}
  cfg.init_options = cfg.init_options or {}

  -- 兜底 root，避免部分服务器无法确定工作目录
  if not cfg.root_dir and not cfg.root_markers then
    cfg.root_dir = vim.fn.getcwd()
  end

  built[server_name] = cfg
  return cfg
end

-- 获取（并按需构建）某服务器完整配置（含能力与内存限制）
function M.get(server_name)
  local runtime = M._server_configs[server_name]
  local base

  if runtime and runtime.cmd then
    base = memory.copy(runtime)
    base.settings = base.settings or {}
    base.init_options = base.init_options or {}
    if not base.root_dir and not base.root_markers then
      base.root_dir = vim.fn.getcwd()
    end
  else
    base = base_config(server_name)
  end

  if not base then
    return nil
  end

  return memory.apply(with_caps(base), server_name)
end

-- 注册单个服务器到内置 API（消除 "config not found" 警告）
function M.register(server_name)
  local cfg = M.get(server_name)
  if not cfg then
    return
  end
  local reg = memory.copy(cfg)
  reg.name = nil -- name 由第一个参数指定
  pcall(vim.lsp.config, server_name, reg)
end

-- 注册全部可用服务器
function M.register_all()
  local names = {}
  for name in pairs(config.default_cmds) do
    names[name] = true
  end
  for _, name in ipairs(M.available()) do
    names[name] = true
  end
  for name in pairs(names) do
    M.register(name)
  end
end

-- 按文件类型启动 LSP（复用同 name/root 的已有客户端）
function M.start_for_filetype(ft, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if config.skip_filetypes[ft] then
    return
  end
  -- 兼容 CodeCompanion / NeoAI 等标记禁用 LSP 的缓冲区
  if vim.b[bufnr].neoai_no_lsp then
    return
  end
  -- 禁用 nofile：无文件支撑的插件 UI / 暂存 / 悬浮窗 buffer 不挂 LSP，
  -- 否则 document_color / semantic_tokens / inline_completion 等会持续空耗 CPU。
  if vim.bo[bufnr].buftype == "nofile" then
    return
  end

  local server_names = config.filetype_mappings[ft]
  if not server_names then
    -- 白名单模式：未列出的文件类型不启动
    vim.b[bufnr].lsp_started = true
    return
  end
  if vim.b[bufnr].lsp_started then
    return
  end

  for _, name in ipairs(server_names) do
    if not memory.can_start_client() then
      break
    end
    local cfg = M.get(name)
    if cfg and cfg.cmd then
      -- 此刻 cmp 已加载，确保注册进内置 API 的配置带有正确能力
      M.register(name)
      -- vim.lsp.start 仅在 opts._root_markers 存在时才解析 root_markers，
      -- 否则 root_markers 会被忽略（root_dir 为空）。这里显式透传。
      local opts = { bufnr = bufnr }
      if cfg.root_markers then
        opts._root_markers = cfg.root_markers
      end
      pcall(vim.lsp.start, cfg, opts)
    end
  end

  vim.b[bufnr].lsp_started = true
end

return M
