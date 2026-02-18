--[[
Neovim虚拟环境检测模块
功能：自动检测并设置Neovim的Python解释器和pyright配置
--]]

local M = {}
-- 记录上次设置的虚拟环境路径
local last_venv_path = nil

local function is_executable(path)
  -- 检查文件是否可执行
  if not path or path == "" then
    return false
  end

  local file = io.open(path, "r")
  if file then
    file:close()
    return vim.fn.executable(path) == 1
  end
  return false
end

local function get_system_python()
  -- 获取系统Python路径
  local handle = io.popen("which python3 2>/dev/null", "r")
  if handle then
    local result = handle:read("*l")
    handle:close()
    if result and result ~= "" and is_executable(result) then
      return result
    end
  end

  handle = io.popen("which python 2>/dev/null", "r")
  if handle then
    local result = handle:read("*l")
    handle:close()
    if result and result ~= "" and is_executable(result) then
      return result
    end
  end
  return "/usr/bin/python3"
end

local function get_venv_python(start_path)
  -- 获取虚拟环境路径
  local start_dir
  if start_path and start_path ~= "" then
    if not start_path:match("/$") then
      start_dir = start_path:match("^(.+)/[^/]+$")
      if not start_dir then
        start_dir = vim.fn.getcwd()
      end
    else
      start_dir = start_path
    end
  else
    start_dir = vim.fn.getcwd()
  end

  local dir = vim.fn.fnamemodify(start_dir, ":p")
  while dir and dir ~= "" and dir ~= "/" do
    local venv_dirs = { ".venv", "venv", "env" }
    local python_names = { "python3", "python" }
    for _, venv_dir in ipairs(venv_dirs) do
      for _, python_name in ipairs(python_names) do
        local venv_python = dir .. venv_dir .. "/bin/" .. python_name
        if is_executable(venv_python) then
          return venv_python, dir .. venv_dir
        end
      end
    end
    local parent = dir:match("^(.+)/[^/]+/$")
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil, nil
end


local function setup_environment(venv_dir)
  -- 设置环境变量
  if not venv_dir then
    return
  end

  vim.env.VIRTUAL_ENV = venv_dir
  local venv_bin = venv_dir .. "/bin"
  if vim.fn.isdirectory(venv_bin) == 1 then
    local current_path = vim.env.PATH or ""
    if not current_path:match(venv_bin) then
      vim.env.PATH = venv_bin .. ":" .. current_path
    end
  end
end

function M.setup_neovim_python()
  -- 为Neovim设置Python解释器
  local buf_path = vim.api.nvim_buf_get_name(0)
  local python_path, venv_dir = get_venv_python(buf_path)
  if not python_path or not is_executable(python_path) then
    python_path = get_system_python()
    venv_dir = nil
  end

  if venv_dir and venv_dir ~= last_venv_path then
    setup_environment(venv_dir)
    last_venv_path = venv_dir
  elseif not venv_dir then
    last_venv_path = nil
  end

  vim.g.python3_host_prog = python_path
  vim.g.python_host_prog = python_path

  return python_path, venv_dir
end

function M.silent_setup()
  -- 静默模式：自动设置但不通知
  local python_path, venv_dir = M.setup_neovim_python()
  return python_path, venv_dir
end

function M.check_config()
  -- 检查Python配置
  local config = {
    python3_host_prog = vim.g.python3_host_prog or "未设置",
    python_host_prog = vim.g.python_host_prog or "未设置",
    VIRTUAL_ENV = vim.env.VIRTUAL_ENV or "未设置",
    PATH = vim.env.PATH and vim.env.PATH:sub(1, 100) .. "..." or "未设置"
  }
  return config
end

function M.setup_autocmds()
  -- 创建自动命令
  vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
    pattern = "*.py",
    callback = function()
      vim.defer_fn(M.silent_setup, 50)
    end,
    desc = "设置Python虚拟环境"
  })

  vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
      vim.defer_fn(function()
        last_venv_path = nil
        M.silent_setup()
      end, 50)
    end,
    desc = "目录改变时重置虚拟环境"
  })
end

function M.get_python_info()
  -- 获取当前Python信息
  local python_path = vim.g.python3_host_prog or get_system_python()
  if not python_path or not is_executable(python_path) then
    return { error = "Python路径无效" }
  end

  local handle = io.popen(python_path .. " -c \"import sys; print(sys.version)\" 2>/dev/null", "r")
  if not handle then
    return { error = "无法执行Python" }
  end

  local version = handle:read("*l")
  handle:close()

  return {
    path = python_path,
    version = version or "未知",
    venv = vim.env.VIRTUAL_ENV or "无",
    is_venv = vim.env.VIRTUAL_ENV and true or false
  }
end

function M.setup()
  -- 初始化模块
  M.setup_autocmds()
  M.silent_setup()
  -- vim.defer_fn(M.silent_setup, 1000)
  vim.api.nvim_create_user_command("SetPythonVenv", function()
    local python_path, venv_dir = M.setup_neovim_python()
    if venv_dir then
      vim.notify(string.format("虚拟环境: %s\nPython路径: %s", venv_dir, python_path), vim.log.levels.INFO,
        { title = "Python设置" })
    else
      vim.notify("系统Python: " .. python_path, vim.log.levels.INFO, { title = "Python设置" })
    end
  end, { desc = "手动设置Python虚拟环境" })

  vim.api.nvim_create_user_command("CheckPythonConfig", function()
    local info = M.get_python_info()
    if info.error then
      vim.notify("错误: " .. info.error, vim.log.levels.ERROR)
    else
      local msg = string.format("Python路径: %s\n版本: %s\n虚拟环境: %s", info.path, info.version, info.venv)
      vim.notify(msg, vim.log.levels.INFO, { title = "Python信息" })
    end
  end, { desc = "检查Python配置" })
end

return M
