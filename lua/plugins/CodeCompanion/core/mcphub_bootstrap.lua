-- mcphub_bootstrap.lua
-- MCP Hub 依赖（mcp-hub 可执行文件）的探测与异步安装引导。
--
-- 背景：mcphub.nvim 插件本身是 Lua 代码，但它在 setup() 时会启动外部的
-- `mcp-hub` CLI 进程。若该可执行文件不存在，mcphub 会抛出
-- `SETUP.MISSING_DEPENDENCY` 错误。此前用 `require("mcphub")` 判断是否安装，
-- 检的是插件而非 CLI，导致误判。
--
-- 本模块以 `vim.fn.executable("mcp-hub")` 作为唯一判据，并在缺失时用
-- 异步 job 安装，避免阻塞 Neovim 启动。

local M = {}

local PKG = "mcp-hub@latest"
local MANUAL_HINT = "请手动运行: npm install -g " .. PKG

-- 是否正在安装（防重入）
local installing = false
-- 等待安装结果的回调队列
local waiters = {}

---mcp-hub 可执行文件是否已就绪
---@return boolean
function M.is_installed()
  return vim.fn.executable("mcp-hub") == 1
end

---通知所有等待者并清空队列
---@param ok boolean
---@param err string|nil
local function flush_waiters(ok, err)
  local pending = waiters
  waiters = {}
  installing = false
  for _, cb in ipairs(pending) do
    pcall(cb, ok, err)
  end
end

---确保 mcp-hub 可用；缺失时异步安装。
---已安装则立即回调；正在安装则排队等待；否则发起安装。
---@param cb fun(ok: boolean, err: string|nil)|nil
function M.ensure(cb)
  if M.is_installed() then
    if cb then
      pcall(cb, true, nil)
    end
    return
  end

  if installing then
    if cb then
      table.insert(waiters, cb)
    end
    return
  end

  -- npm 不可用时直接回退到手动提示，避免抛出 ERROR
  if vim.fn.executable("npm") ~= 1 then
    vim.notify("未找到 npm，无法自动安装 MCP Hub。\n" .. MANUAL_HINT, vim.log.levels.WARN)
    if cb then
      pcall(cb, false, "npm not found")
    end
    return
  end

  installing = true
  if cb then
    table.insert(waiters, cb)
  end
  vim.notify("MCP Hub 依赖缺失，正在后台安装 " .. PKG .. " ...", vim.log.levels.INFO)

  vim.fn.jobstart({ "npm", "install", "-g", PKG }, {
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 and M.is_installed() then
          vim.notify("MCP Hub 安装成功: mcp-hub 已可用", vim.log.levels.INFO)
          flush_waiters(true, nil)
        else
          vim.notify(
            "MCP Hub 自动安装失败（退出码 " .. tostring(code) .. "）。\n" .. MANUAL_HINT,
            vim.log.levels.WARN
          )
          flush_waiters(false, "install failed, exit code " .. tostring(code))
        end
      end)
    end,
  })
end

return M
