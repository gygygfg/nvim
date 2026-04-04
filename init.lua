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

-- 加载状态管理
local load_state = {
  core_loaded = false,
  plugins_loaded = false
}

-- 定义 on_all_loaded 函数（放在文件开头，确保全局可访问）
local function on_all_loaded()
  if not load_state.core_loaded or not load_state.plugins_loaded then
    return
  end
  
  vim.notify('Neovim 配置加载完成', vim.log.levels.INFO)
  
  -- 延迟执行 VimEnter 逻辑
  vim.defer_fn(function()
    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        vim.notify('Vim 已完全启动', vim.log.levels.INFO)
        -- 这里执行 VimEnter 相关代码
        local ui_config_ok, ui_config = pcall(require, 'config.ui')
        if ui_config_ok and ui_config.setup_final_ui then
          ui_config.setup_final_ui()
        end
      end,
      once = true
    })
  end, 100)
end

-- 加载核心配置
local function load_core()
  if load_state.core_loaded then return end
  
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
  
  load_state.core_loaded = true
  on_all_loaded()  -- 检查是否全部加载完成
end

-- 加载插件配置
local function load_plugins()
  if load_state.plugins_loaded then return end
  
  local plugin_loader = require("plugins").setup({
    use_async = true,
    on_progress = function(config_files, loaded, failed, total, results)
      -- 只打印一次进度
      if loaded + failed == 1 then
        vim.notify(string.format("开始加载 %d 个配置文件...", total), vim.log.levels.INFO)
      end
    end,
    on_complete = function(results, loaded, failed)
      vim.notify(string.format('配置加载完成: %d成功, %d失败', loaded, failed), vim.log.levels.INFO)
      load_state.plugins_loaded = true
      on_all_loaded()  -- 检查是否全部加载完成
    end
  })
end

-- 主加载流程
load_core()
load_plugins()
