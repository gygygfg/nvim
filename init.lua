-- ~/.config/nvim/init.lua

-- 获取当前 init.lua 文件所在目录
local config_dir = vim.fn.fnamemodify(vim.fn.expand('<sfile>'), ':p:h')
local lua_dir = config_dir .. '/lua'

-- 将 lua 目录添加到 Lua 的 package.path 中
package.path = package.path .. ';' .. lua_dir .. '/?.lua;' .. lua_dir .. '/?/init.lua'
-- 确保插件目录存在
local function ensure_dir(path) vim.fn.mkdir(path, "p") end
ensure_dir(vim.fn.stdpath("data") .. "/site/pack/plugins/opt")
ensure_dir(vim.fn.stdpath("data") .. "/site/pack/plugins/start")


-- 加载核心配置
require("core.options")      -- 选项配置
require("core.autocommands") -- 自动命令配置
require("core.keymaps").setup()

-- 加载 NVM 初始化
local nvm_ok, nvm = pcall(require, "core.nvm_init")
if nvm_ok then
  nvm.setup()
else
  vim.notify("NVM 初始化模块加载失败", vim.log.levels.WARN)
end

-- 加载 Python 虚拟环境配置
local python_venv_ok, python_venv = pcall(require, "core.python_venv")
if python_venv_ok then
  python_venv.setup()
else
  vim.notify("Python 虚拟环境模块加载失败", vim.log.levels.WARN)
end

require("plugins").setup()
