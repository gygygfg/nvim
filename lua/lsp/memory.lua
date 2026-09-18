-- ~/.config/nvim/lua/lsp/memory.lua
-- LSP 内存管理：动态限制计算 + 启动前并发检查
-- 说明：仅保留「限制内存占用」的核心能力，不包含进程/僵尸扫描等自建监控逻辑。

local config = require("lsp.config")

local M = {}

-- 安全深拷贝：函数等不可拷贝值按引用保留（vim.deepcopy 遇到函数会报错，
-- 而 godot_editor 的 cmd 是 vim.lsp.rpc.connect 返回的函数）。
local function safe_copy(t)
  if type(t) ~= "table" then
    return t
  end
  local out = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      out[k] = safe_copy(v)
    else
      out[k] = v
    end
  end
  return out
end

M.copy = safe_copy

-- 读取系统内存信息（Linux /proc/meminfo），非 Linux 返回空表
local function get_system_memory_info()
  local info = {}
  local file = io.open("/proc/meminfo", "r")
  if not file then
    return info
  end

  for line in file:lines() do
    if line:match("^MemTotal:") then
      local kb = tonumber(line:match("%d+")) or 0
      info.total_mb = math.floor(kb / 1024)
      info.total_gb = math.floor(info.total_mb / 1024 * 10) / 10
    elseif line:match("^MemAvailable:") then
      info.available_kb = tonumber(line:match("%d+")) or 0
    elseif line:match("^MemFree:") then
      info.free_kb = tonumber(line:match("%d+")) or 0
    end
  end
  file:close()

  if info.total_mb and info.total_mb > 0 then
    local used_kb = info.total_mb * 1024 - (info.available_kb or info.free_kb or 0)
    info.usage_percent = math.floor(used_kb / (info.total_mb * 1024) * 100)
  end

  return info
end

-- 根据系统内存动态计算限制（用户显式配置 > 0 时优先使用）
local function calculate_dynamic_limits()
  local user = config.options.memory_limit
  local info = get_system_memory_info()
  local total_gb = info.total_gb or 8

  local limits = {
    max_concurrent_clients = 3,
    max_memory_per_client = 512,
    max_workspace_files = 1000,
    lua_max_items = 1000,
    system_memory_gb = total_gb,
  }

  if total_gb <= 4 then
    limits.max_concurrent_clients = 2
    limits.max_memory_per_client = 256
    limits.max_workspace_files = 500
    limits.lua_max_items = 500
  elseif total_gb <= 8 then
    limits.max_concurrent_clients = 3
    limits.max_memory_per_client = 512
    limits.max_workspace_files = 1000
    limits.lua_max_items = 1000
  elseif total_gb <= 16 then
    limits.max_concurrent_clients = 5
    limits.max_memory_per_client = 1024
    limits.max_workspace_files = 2000
    limits.lua_max_items = 2000
  elseif total_gb <= 32 then
    limits.max_concurrent_clients = 8
    limits.max_memory_per_client = 2048
    limits.max_workspace_files = 5000
    limits.lua_max_items = 5000
  else
    limits.max_concurrent_clients = 12
    limits.max_memory_per_client = 4096
    limits.max_workspace_files = 10000
    limits.lua_max_items = 10000
  end

  -- 依据当前内存占用率自适应微调
  if info.usage_percent and info.usage_percent > 80 then
    limits.max_concurrent_clients = math.max(2, limits.max_concurrent_clients - 1)
    limits.max_memory_per_client = math.max(256, limits.max_memory_per_client * 0.8)
    limits.max_workspace_files = math.max(500, limits.max_workspace_files * 0.7)
    limits.lua_max_items = math.max(500, limits.lua_max_items * 0.7)
  elseif info.usage_percent and info.usage_percent < 40 then
    limits.max_concurrent_clients = limits.max_concurrent_clients + 1
    limits.max_memory_per_client = limits.max_memory_per_client * 1.2
    limits.max_workspace_files = limits.max_workspace_files * 1.3
    limits.lua_max_items = limits.lua_max_items * 1.3
  end

  -- 用户显式配置覆盖（> 0 生效）
  if user.max_concurrent_clients and user.max_concurrent_clients > 0 then
    limits.max_concurrent_clients = user.max_concurrent_clients
  end
  if user.max_memory_per_client and user.max_memory_per_client > 0 then
    limits.max_memory_per_client = user.max_memory_per_client
  end
  if user.max_workspace_files and user.max_workspace_files > 0 then
    limits.max_workspace_files = user.max_workspace_files
  end

  limits.max_concurrent_clients = math.floor(limits.max_concurrent_clients)
  limits.max_memory_per_client = math.floor(limits.max_memory_per_client)
  limits.max_workspace_files = math.floor(limits.max_workspace_files)
  limits.lua_max_items = math.floor(limits.lua_max_items)

  return limits
end

M.get_limits = calculate_dynamic_limits

-- 启动前并发检查：返回 true 表示允许再启动一个客户端
function M.can_start_client()
  if not config.options.memory_limit.enabled then
    return true
  end

  local active = 0
  for _, client in ipairs(vim.lsp.get_clients()) do
    if #client.attached_buffers > 0 then
      active = active + 1
    end
  end

  return active < calculate_dynamic_limits().max_concurrent_clients
end

-- 为指定服务器配置注入内存限制（返回新表，不修改原表）
function M.apply(config_in, server_name)
  if not config.options.memory_limit.enabled then
    return config_in
  end

  local cfg = safe_copy(config_in)
  cfg.settings = cfg.settings or {}
  cfg.init_options = cfg.init_options or {}

  local limits = calculate_dynamic_limits()
  local memory_kb = limits.max_memory_per_client * 1024
  local s = cfg.settings

  if server_name == "lua_ls" then
    s.Lua = s.Lua or {}
    s.Lua.workspace = s.Lua.workspace or {}
    s.Lua.diagnostics = s.Lua.diagnostics or {}
    s.Lua.completion = s.Lua.completion or {}
    s.Lua.hint = s.Lua.hint or {}

    if config.options.memory_limit.limit_workspace_size then
      s.Lua.workspace.maxPreload = math.min(s.Lua.workspace.maxPreload or 10000, limits.max_workspace_files)
      s.Lua.workspace.preloadFileSize = math.min(s.Lua.workspace.preloadFileSize or 10000, 5000)
      s.Lua.workspace.checkThirdParty = false
      s.Lua.workspace.maxLibraryFiles =
        math.min(s.Lua.workspace.maxLibraryFiles or 5000, limits.lua_max_items)
    end

    s.Lua.diagnostics.workspaceRate = 30
    s.Lua.diagnostics.workspaceDelay = 1500
    s.Lua.diagnostics.disable = s.Lua.diagnostics.disable or {}
    table.insert(s.Lua.diagnostics.disable, "codestyle-check")
    s.Lua.diagnostics.maxItems = math.min(s.Lua.diagnostics.maxItems or 1000, limits.lua_max_items)
    s.Lua.diagnostics.globals = s.Lua.diagnostics.globals or {}
    if #s.Lua.diagnostics.globals > 100 then
      local limited = {}
      for i = 1, 100 do
        limited[i] = s.Lua.diagnostics.globals[i]
      end
      s.Lua.diagnostics.globals = limited
    end

    s.Lua.completion.maxItems = math.min(s.Lua.completion.maxItems or 500, math.floor(limits.lua_max_items / 2))
    s.Lua.completion.autoRequire = false
    s.Lua.completion.showWord = "Disable"

    s.Lua.hint.enable = true
    s.Lua.hint.arrayIndex = "Disable"
    s.Lua.hint.paramType = false
    s.Lua.hint.setType = false

    s.Lua.semantic = s.Lua.semantic or {}
    s.Lua.semantic.enable = false
    s.Lua.color = s.Lua.color or {}
    s.Lua.color.mode = "Disable"
    s.Lua.telemetry = { enable = false }
    s.Lua.format = s.Lua.format or {}
    s.Lua.format.enable = false
    s.Lua.runtime = s.Lua.runtime or {}
    s.Lua.runtime.special = {}
    s.Lua.memoryLimit = memory_kb
    s.Lua.performanceMode = "low"
  elseif server_name == "pyright" then
    s.python = s.python or {}
    s.python.analysis = s.python.analysis or {}
    s.python.analysis.autoSearchPaths = false
    s.python.analysis.useLibraryCodeForTypes = false
    s.python.analysis.diagnosticMode = "workspace"
    s.python.analysis.typeCheckingMode = "basic"
    s.python.analysis.memory = { heapSize = memory_kb }
  elseif server_name == "ts_ls" or server_name == "tsserver" then
    s.typescript = s.typescript or {}
    s.typescript.maxTsServerMemory = memory_kb * 1024
    s.typescript.suggest = s.typescript.suggest or {}
    s.typescript.suggest.autoImports = false
    s.typescript.suggest.paths = false
    s.javascript = s.javascript or {}
    s.javascript.suggest = s.javascript.suggest or {}
    s.javascript.suggest.autoImports = false
    s.javascript.suggest.paths = false
    s.typescript.maxProjectFileCount = limits.max_workspace_files
    s.javascript.maxProjectFileCount = limits.max_workspace_files
  elseif server_name == "clangd" then
    s.clangd = s.clangd or {}
    s.clangd.memoryLimit = memory_kb
    s.clangd.maxIndexFileSize = 5000
    s.clangd.maxSymbolIndexFiles = 1000
  elseif server_name == "rust_analyzer" then
    s.rust_analyzer = s.rust_analyzer or {}
    s.rust_analyzer.maxMemoryUsage = memory_kb * 1024
    s.rust_analyzer.checkOnSave = s.rust_analyzer.checkOnSave or {}
    s.rust_analyzer.checkOnSave.allTargets = false
    s.rust_analyzer.cargo = s.rust_analyzer.cargo or {}
    s.rust_analyzer.cargo.allFeatures = false
    s.rust_analyzer.cargo.noDefaultFeatures = true
  elseif server_name == "gopls" then
    s.gopls = s.gopls or {}
    s.gopls.memoryMode = "Degrade"
    s.gopls.staticcheck = false
    s.gopls.completeUnimported = false
    s.gopls.deepCompletion = false
  elseif server_name == "html" or server_name == "cssls" or server_name == "jsonls" then
    s.html = s.html or {}
    s.html.suggest = s.html.suggest or {}
    s.html.suggest.html5 = false
    s.css = s.css or {}
    s.css.suggest = s.css.suggest or {}
    s.css.suggest.completePropertyWithSemicolon = false
    s.json = s.json or {}
    s.json.suggest = s.json.suggest or {}
    s.json.suggest.comments = false
  elseif server_name == "yamlls" then
    s.yaml = s.yaml or {}
    s.yaml.schemaStore = { enable = false }
    s.yaml.schemas = {}
  end

  cfg.init_options.memoryLimit = memory_kb
  cfg.init_options.performanceMode = "low"

  return cfg
end

return M
