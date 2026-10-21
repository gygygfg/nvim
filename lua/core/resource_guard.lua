--- 低内存服务门控（Resource Guard）
--- @module 'core.resource_guard'
---
--- 存在意义：copilot 与 mcp-hub 这类常驻 AI 服务在启动期即拉起独立进程，
--- copilot-language-server 单个常驻约 200 MB、mcp-hub（node）约 40 MB。
--- 在 2 核 / 1.6 GB / 无 swap 的小内存主机上，它们是整机内存被打满的主要贡献者，
--- 结果是 nvim 卡顿、乃至 sshd 连 SSH banner 都返回不了（TCP 可连但协议无响应）。
---
--- 策略：启动时读一次 /proc/meminfo 的可用内存（MemAvailable；内核 < 3.14 时回退
--- MemFree + Buffers + Cached），低于阈值（默认 4 GB）则不自动启动这些服务。
---
--- 三条原则：
---   1. **探测不到就不禁用**：读不到 /proc/meminfo（Android/Termux、裁剪容器）时一律
---      视为内存充足，绝不因探测失败而砍掉功能。
---   2. **只读一次**：服务是启动期拉起的，判定一次并缓存即可，不在热路径读 /proc。
---   3. **只影响「自动启动」**：包仍在 opt 目录里装着，需要时随时手动启用：
---        :packadd copilot.vim        -- 手动启用 copilot
---      或用环境变量放宽阈值后重启 nvim：
---        NVIM_SERVICE_MIN_MEM_MIB=0  -- 0/非法值 → 视为无阈值，等价于永不跳过
---        NVIM_FORCE_SERVICES=1       -- 强制启用全部服务

local M = {}

-- ========== 私有常量 ==========

local MIB = 1024 * 1024
--- 默认阈值：可用内存低于 4 GB 时不自动启动常驻 AI 服务
local DEFAULT_THRESHOLD_MIB = 4096

-- ========== 私有状态 ==========

local state = {
  probed = false,      -- 是否已探测过
  available = nil,     -- 可用内存字节数（探测失败为 nil）
  skipped = {},        -- 本次启动被跳过的服务名
  notice_scheduled = false,
}

-- ========== 私有函数 ==========

--- 读取环境变量中的正整数（非法或缺失时返回默认值）
--- @param name string 环境变量名
--- @param default number 默认值
--- @return number
local function _env_number(name, default)
  local raw = vim.env[name]
  if not raw or raw == "" then return default end
  local n = tonumber(raw)
  if not n or n <= 0 then return default end
  return n
end

--- 探测可用内存（字节）。读不到 /proc/meminfo 或其中无 MemTotal 时返回 nil。
--- @return number|nil
local function _probe_available()
  local f = io.open("/proc/meminfo", "r")
  if not f then return nil end
  local ok, data = pcall(f.read, f, "*a")
  f:close()
  if not ok or type(data) ~= "string" then return nil end
  local fields = {}
  for key, val in data:gmatch("([%w_]+):%s*(%d+)") do
    fields[key] = tonumber(val) * 1024 -- meminfo 单位为 kB，统一换算为字节
  end
  if not fields.MemTotal or fields.MemTotal <= 0 then return nil end
  if fields.MemAvailable then return fields.MemAvailable end
  -- 内核 < 3.14 无 MemAvailable：回退 MemFree + Buffers + Cached（与 free 的估算同源）
  local free = fields.MemFree
  if not free then return nil end
  return free + (fields.Buffers or 0) + (fields.Cached or 0)
end

--- 记录一次跳过并在本 tick 结束后合并提示（避免每个服务各弹一次）
--- @param name string 服务名
local function _note_skip(name)
  state.skipped[#state.skipped + 1] = name
  if state.notice_scheduled then return end
  state.notice_scheduled = true
  vim.schedule(function()
    local avail = state.available or 0
    vim.notify(
      string.format(
        "已跳过启动 %s：可用内存 %d MB < 阈值 %d MB。\n"
          .. "包仍在 opt 目录中，需要时手动启用（如 :packadd copilot.vim），"
          .. "或设 NVIM_SERVICE_MIN_MEM_MIB=0 / NVIM_FORCE_SERVICES=1 后重启。",
        table.concat(state.skipped, "、"),
        math.floor(avail / MIB),
        math.floor(M.threshold_bytes() / MIB)
      ),
      vim.log.levels.WARN
    )
  end)
end

-- ========== 公开 API ==========

--- 可用内存字节数（首次调用探测并缓存；探测失败返回 nil）
--- @return number|nil
function M.available_bytes()
  if not state.probed then
    state.probed = true
    state.available = _probe_available()
  end
  return state.available
end

--- 阈值字节数（环境变量 NVIM_SERVICE_MIN_MEM_MIB 可覆盖，默认 4096 MiB）
--- @return number
function M.threshold_bytes()
  return _env_number("NVIM_SERVICE_MIN_MEM_MIB", DEFAULT_THRESHOLD_MIB) * MIB
end

--- 当前是否处于「可用内存不足」状态
--- 探测失败（无 /proc/meminfo）或 NVIM_FORCE_SERVICES=1 时恒为 false。
--- @return boolean
function M.low_memory()
  if vim.env.NVIM_FORCE_SERVICES == "1" then return false end
  local avail = M.available_bytes()
  if not avail then return false end -- 探测不到 → 不禁用（绝不误砍功能）
  return avail < M.threshold_bytes()
end

--- 判定某服务是否应当启动（低内存时记录跳过并合并提示）
--- @param name string 服务名（用于提示文案）
--- @return boolean allowed
function M.decide(name)
  if not M.low_memory() then return true end
  _note_skip(tostring(name or "服务"))
  return false
end

--- 一次性汇总信息（调试 / 诊断用）
--- @return table { available_mb, threshold_mb, low_memory, skipped }
function M.summary()
  local avail = M.available_bytes()
  return {
    available_mb = avail and math.floor(avail / MIB) or nil,
    threshold_mb = math.floor(M.threshold_bytes() / MIB),
    low_memory = M.low_memory(),
    skipped = vim.deepcopy(state.skipped),
  }
end

--- 重置缓存与记录（测试用）
function M.reset()
  state.probed = false
  state.available = nil
  state.skipped = {}
  state.notice_scheduled = false
end

return M
