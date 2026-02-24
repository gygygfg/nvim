--[[
Neovim虚拟环境检测模块
功能：自动检测并设置Neovim的Python解释器和pyright配置
支持pipx虚拟环境检测
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

local function is_pipx_managed(python_path)
  -- 检查Python是否由pipx管理
  if not python_path then
    return false
  end

  -- 检查路径是否包含pipx相关目录
  if python_path:match("/%.local/pipx/") or python_path:match("/pipx/venvs/") then
    return true
  end

  -- 检查是否是pipx包装脚本
  local handle = io.popen(string.format("file %s 2>/dev/null", python_path), "r")
  if handle then
    local file_info = handle:read("*l")
    handle:close()
    if file_info and file_info:match("Python script") then
      -- 检查脚本内容
      handle = io.popen(string.format("head -n 5 %s 2>/dev/null", python_path), "r")
      if handle then
        local content = handle:read("*a")
        handle:close()
        if content and content:match("pipx") then
          return true
        end
      end
    end
  end

  return false
end

local function get_system_python()
  -- 获取系统Python路径，优先考虑pipx管理的Python

  -- 首先检查常见的pipx Python路径
  local pipx_paths = {
    vim.env.HOME .. "/.local/bin/python3",
    vim.env.HOME .. "/.local/bin/python",
    "/usr/local/bin/python3",
    "/usr/local/bin/python",
  }

  for _, path in ipairs(pipx_paths) do
    if is_executable(path) then
      -- 检查是否是pipx包装的脚本
      local handle = io.popen(string.format("head -n 1 %s 2>/dev/null", path), "r")
      if handle then
        local first_line = handle:read("*l")
        handle:close()
        -- 如果不是pipx包装脚本（没有shebang或不是pipx），则使用
        if not first_line or not first_line:match("pipx") then
          return path
        end
      end
    end
  end

  -- 使用which命令查找系统Python
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

  -- 最后尝试标准路径
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

  -- 首先检查项目虚拟环境（优先级最高）
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

  -- 如果没有找到项目虚拟环境，检查pipx虚拟环境
  local pipx_home = vim.env.PIPX_HOME or vim.env.HOME .. "/.local/pipx/venvs"
  if vim.fn.isdirectory(pipx_home) == 1 then
    local pipx_dirs = vim.fn.glob(pipx_home .. "/*", true, true)
    for _, pipx_dir in ipairs(pipx_dirs) do
      local python_names = { "python3", "python" }
      for _, python_name in ipairs(python_names) do
        local pipx_python = pipx_dir .. "/bin/" .. python_name
        if is_executable(pipx_python) then
          return pipx_python, pipx_dir
        end
      end
    end
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
  -- 获取当前Python信息，包括pipx状态
  local python_path = vim.g.python3_host_prog or get_system_python()
  if not python_path or not is_executable(python_path) then
    return { error = "Python路径无效" }
  end

  -- 获取Python版本
  local handle = io.popen(python_path .. " -c \"import sys; print(sys.version)\" 2>/dev/null", "r")
  if not handle then
    return { error = "无法执行Python" }
  end

  local version = handle:read("*l")
  handle:close()

  -- 检查是否是pipx管理
  local pipx_managed = is_pipx_managed(python_path)

  -- 获取pipx应用信息（如果适用）
  local pipx_app = ""
  if pipx_managed then
    -- 尝试从路径推断pipx应用名称
    if python_path:match("/pipx/venvs/([^/]+)/") then
      pipx_app = python_path:match("/pipx/venvs/([^/]+)/")
    end

    -- 或者检查是否是pipx包装脚本
    if python_path:match("/%.local/bin/") then
      local app_name = python_path:match("/([^/]+)$")
      if app_name then
        pipx_app = app_name
      end
    end
  end

  return {
    path = python_path,
    version = version or "未知",
    venv = vim.env.VIRTUAL_ENV or "无",
    is_venv = vim.env.VIRTUAL_ENV and true or false,
    pipx_managed = pipx_managed,
    pipx_app = pipx_app or "",
    is_pipx = pipx_managed
  }
end

function M.setup()
  -- 初始化模块
  M.setup_autocmds()
  M.silent_setup()

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
      local msg_lines = {
        string.format("Python路径: %s", info.path),
        string.format("版本: %s", info.version),
        string.format("虚拟环境: %s", info.venv),
      }

      -- 添加pipx信息
      if info.pipx_managed then
        table.insert(msg_lines, string.format("pipx管理: 是"))
        if info.pipx_app and info.pipx_app ~= "" then
          table.insert(msg_lines, string.format("pipx应用: %s", info.pipx_app))
        end
      else
        table.insert(msg_lines, "pipx管理: 否")
      end

      local msg = table.concat(msg_lines, "\n")
      vim.notify(msg, vim.log.levels.INFO, { title = "Python信息" })
    end
  end, { desc = "检查Python配置" })

  vim.api.nvim_create_user_command("CheckPipxEnv", function()
    -- 检查pipx环境
    local pipx_home = vim.env.PIPX_HOME or vim.env.HOME .. "/.local/pipx/venvs"
    local pipx_dirs = vim.fn.glob(pipx_home .. "/*", true, true)

    if #pipx_dirs == 0 then
      vim.notify("未找到pipx虚拟环境", vim.log.levels.WARN, { title = "pipx检查" })
      return
    end

    local msg_lines = {
      string.format("pipx目录: %s", pipx_home),
      string.format("找到 %d 个pipx虚拟环境:", #pipx_dirs),
      "",
    }

    for i, dir in ipairs(pipx_dirs) do
      local app_name = dir:match("/([^/]+)$")
      local python_path = dir .. "/bin/python3"
      local python_exists = vim.fn.filereadable(python_path) == 1

      table.insert(msg_lines, string.format("%d. %s", i, app_name))
      table.insert(msg_lines, string.format("   路径: %s", dir))
      table.insert(msg_lines, string.format("   Python: %s", python_exists and "存在" or "缺失"))
      table.insert(msg_lines, "")
    end

    local msg = table.concat(msg_lines, "\n")
    vim.notify(msg, vim.log.levels.INFO, { title = "pipx虚拟环境" })
  end, { desc = "检查pipx虚拟环境" })
end

return M
