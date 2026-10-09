-- ~/.config/nvim/lua/lsp/servers.lua
-- LSP 服务器：加载 lsp/configs/<name>.lua 配置、注册到 Neovim 内置 API、
-- 并统一通过 vim.lsp.enable 启动（Neovim 0.12 原生机制）。
--
-- 设计要点：
--   * 配置来源单一：静态数据读 lsp/config.lua（filetype_mappings 等），
--     每个服务器的细节读 lsp/configs/<name>.lua。
--   * filetypes 白名单：以 config.filetype_mappings 反推（唯一来源），
--     configs/<name>.lua 自带的 filetypes 作为兜底，保证原生
--     can_start 的判定与旧的白名单语义一致（例如 html 同时挂 cssls）。
--   * capabilities 必须为「表」（原生 validate 不接受函数），因此在注册时
--     烘焙 cmp_nvim_lsp 的能力。cmp 在 require("lsp").setup() 之后才由
--     plugins/cmp.lua 加载，故插件加载完成后需调用 M.refresh() 重新烘焙。

local config = require("lsp.config")
local memory = require("lsp.memory")

local M = {}

-- 基础配置缓存（不含 capabilities，capabilities 在注册时烘焙）
local built = {}

-- 已成功注册到 vim.lsp.config 的服务器名
local registered = {}

-- 最近一次注册的完整配置（供命令/调试查看，键为服务器名）
M._server_configs = {}

-- 运行期覆盖表（供 godotdev 等外部插件同步配置使用，可选）
M._server_runtime = {}

-- 读取单个服务器配置（来自 lua/lsp/configs/<name>.lua）
local function load_config_file(server_name)
  local ok, mod = pcall(require, "lsp.configs." .. server_name)
  if ok and type(mod) == "table" then
    return mod
  end
  return {}
end

-- 默认客户端能力：优先使用 cmp_nvim_lsp（启用 snippet / 补全增强能力）
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

-- 由 config.filetype_mappings 反推某服务器应激活的文件类型集合。
-- 若映射中未登记该服务器，则回退到配置文件自带的 filetypes。
local function filetypes_for(server_name, cfg)
  local fts = {}
  for ft, servers in pairs(config.filetype_mappings) do
    for _, s in ipairs(servers) do
      if s == server_name then
        fts[#fts + 1] = ft
        break
      end
    end
  end
  table.sort(fts)
  if #fts == 0 and type(cfg.filetypes) == "table" then
    fts = vim.deepcopy(cfg.filetypes)
    table.sort(fts)
  end
  return #fts > 0 and fts or nil
end

-- 白名单内所有服务器名集合（config.filetype_mappings 中出现的服务器）
local function whitelist_servers()
  local set = {}
  for _, servers in pairs(config.filetype_mappings) do
    for _, name in ipairs(servers) do
      set[name] = true
    end
  end
  return set
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
  table.sort(servers)
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

  -- filetypes 以白名单映射为准（回退到配置文件自带值）
  local fts = filetypes_for(server_name, cfg)
  if fts then
    cfg.filetypes = fts
  end

  -- 根目录：优先使用配置文件提供的 root_dir / root_markers；
  -- 二者皆无时给一个通用兜底标记，避免 root 为 nil 影响项目级特性。
  if not cfg.root_dir and not cfg.root_markers then
    cfg.root_markers = { ".git" }
  end

  built[server_name] = cfg
  return cfg
end

-- 获取某服务器完整配置（含烘焙后的能力与内存限制）
function M.get(server_name)
  local base = base_config(server_name)
  if not base then
    return nil
  end
  -- 运行期动态注入的配置（如外部插件同步过来的）优先
  local runtime = M._server_runtime[server_name]
  if runtime and runtime.cmd then
    base = vim.tbl_deep_extend("force", base, runtime)
  end
  return memory.apply(with_caps(base), server_name)
end

-- 注册单个服务器到内置 API（消除 "config not found" 警告）
function M.register(server_name)
  local cfg = M.get(server_name)
  if not cfg then
    return false
  end
  local reg = memory.copy(cfg)
  reg.name = nil -- name 由 vim.lsp.config 的第一个参数指定
  local ok = pcall(vim.lsp.config, server_name, reg)
  if ok then
    registered[server_name] = true
    M._server_configs[server_name] = cfg
  end
  return ok
end

-- 注册白名单内全部服务器
function M.register_all()
  for name in pairs(whitelist_servers()) do
    M.register(name)
  end
end

-- 统一启用（vim.lsp.enable）：跳过由外部插件托管的服务器
function M.enable_all()
  local enabled = {}
  for name in pairs(whitelist_servers()) do
    if not config.options.external_lsp_servers[name] then
      local ok = pcall(vim.lsp.enable, name)
      if ok then
        enabled[#enabled + 1] = name
      end
    end
  end
  table.sort(enabled)
  return enabled
end

-- 重新注册全部已注册服务器。
-- 用途：cmp 在 require("lsp").setup() 之后才加载，插件就绪后调用本函数
-- 重新烘焙 capabilities（vim.lsp.config 会失效缓存的 resolved_config，
-- 后续 FileType 事件即以新能力启动客户端）。
function M.refresh()
  for name in pairs(registered) do
    M.register(name)
  end
end

-- 白名单服务器名列表（升序），供命令展示
function M.whitelist()
  local names = {}
  for name in pairs(whitelist_servers()) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

return M
