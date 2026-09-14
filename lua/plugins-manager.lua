-- plugins-manager.lua
-- 动态加载 plugins 目录下一层的所有 .lua 文件和含 init.lua 的子文件夹

local M = {}

-- 剔除 package.path 中的 cwd 相对路径 (./?.lua 等)。
-- 否则在 plugins 目录下启动 nvim 时，配置文件名如 lualine.lua 会遮蔽
-- 同名插件模块 (require("lualine") 命中 ./lualine.lua), 造成循环 require。
package.path = table.concat(
  vim.tbl_filter(function(p)
    return p ~= ""
  end, vim.split(package.path, ";")),
  ";"
)
package.path = table.concat(
  vim.tbl_filter(function(p)
    return not p:match("^%./")
  end, vim.split(package.path, ";")),
  ";"
)

local function plugins_dir()
  return vim.fn.stdpath("config") .. "/lua/plugins"
end

local function load_module(name)
  local ok, err = pcall(require, name)
  if not ok then
    vim.notify(string.format("❌ 无法加载插件: %s\n%s", name, err), vim.log.levels.ERROR)
  end
  return ok
end

function M.load_all_plugins()
  local dir = plugins_dir()
  local loaded, failed = 0, 0
  local handle = vim.uv.fs_scandir(dir)

  if not handle then
    vim.notify("插件目录不存在: " .. dir, vim.log.levels.WARN)
    return 0, 0
  end

  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end

    if type == "file" and name:match("%.lua$") and name ~= "plugins-manager.lua" then
      if load_module("plugins." .. name:gsub("%.lua$", "")) then
        loaded = loaded + 1
      else
        failed = failed + 1
      end
    elseif type == "directory"
      and vim.fn.filereadable(dir .. "/" .. name .. "/init.lua") == 1
    then
      if load_module("plugins." .. name) then
        loaded = loaded + 1
      else
        failed = failed + 1
      end
    end
  end

  vim.notify(
    string.format("✨ 插件加载完成! 成功: %d, 失败: %d", loaded, failed),
    vim.log.levels.INFO
  )
  return loaded, failed
end

function M.setup(opts)
  opts = opts or {}
  if opts.auto_load then
    M.load_all_plugins()
  end
end

return M
