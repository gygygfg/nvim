-- Mason lsp 配置
-- 迁移自: servers/pyright.lua
-- 时间: 2026-03-29 20:37:04

-- Mason 安装: pyright
local M = {}

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

local function get_pyright_config()
  -- 定义一个函数来获取更新的 pyright 配置
  local buf_path = vim.api.nvim_buf_get_name(0)
  local python_path, venv_dir = get_venv_python(buf_path)
  if not python_path or not is_executable(python_path) then
    python_path = get_system_python()
    venv_dir = nil
  end

  local config = {
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
    filetypes = { "python" },
    settings = {
      python = {
        pythonPath = python_path,
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "workspace",
          typeCheckingMode = "basic" -- 可改为 "strict" 或 "off"
        }
      }
    }
  }

  if venv_dir then
    config.settings.python.venvPath = vim.fn.fnamemodify(venv_dir, ":h")

    -- Initialize extraPaths to include virtual environment packages
    config.settings.python.analysis = config.settings.python.analysis or {}
    config.settings.python.analysis.extraPaths = config.settings.python.analysis.extraPaths or {}

    -- Add virtual environment site-packages to extraPaths for import resolution (supports both pip and uv)
    local possible_paths = {
      venv_dir .. "/lib/python*/site-packages",         -- Traditional pip venv
      venv_dir .. "/libexec/lib/python*/site-packages", -- UV virtual environment structure in some cases
      venv_dir .. "/lib/python*/dist-packages",         -- Some Linux distributions
      venv_dir .. "/Lib/site-packages",                 -- Windows style (just in case)
    }

    for _, site_packages_pattern in ipairs(possible_paths) do
      local matches = vim.fn.glob(site_packages_pattern, true, true)
      if matches and #matches > 0 then
        for _, path in ipairs(matches) do
          if vim.fn.isdirectory(path) == 1 then
            local path_exists = false
            for _, existing_path in ipairs(config.settings.python.analysis.extraPaths) do
              if existing_path == path then
                path_exists = true
                break
              end
            end
            if not path_exists then
              table.insert(config.settings.python.analysis.extraPaths, path)
            end
          end
        end
      end
    end

    -- Also check for specific Python version paths that might be missed by glob
    local python_version_dirs = vim.fn.glob(venv_dir .. "/lib/python*", true, true)
    for _, py_dir in ipairs(python_version_dirs) do
      local site_packages_path = py_dir .. "/site-packages"
      if vim.fn.isdirectory(site_packages_path) == 1 then
        local path_exists = false
        for _, existing_path in ipairs(config.settings.python.analysis.extraPaths) do
          if existing_path == site_packages_path then
            path_exists = true
            break
          end
        end
        if not path_exists then
          table.insert(config.settings.python.analysis.extraPaths, site_packages_path)
        end
      end
    end

    -- Also try to find site-packages in a more generic way for UV
    local python_executable = venv_dir .. "/bin/python"
    if vim.fn.executable(python_executable) == 1 then
      -- Execute Python to find site-packages programmatically
      local handle = io.popen(python_executable .. " -c \"import site; print('\\n'.join(site.getsitepackages()))\"")
      if handle then
        local result = handle:read("*a")
        handle:close()
        if result and result ~= "" then
          for path in result:gmatch("[^\r\n]+") do
            path = vim.trim(path)
            if path ~= "" and vim.fn.isdirectory(path) == 1 then
              local path_exists = false
              for _, existing_path in ipairs(config.settings.python.analysis.extraPaths) do
                if existing_path == path then
                  path_exists = true
                  break
                end
              end
              if not path_exists then
                table.insert(config.settings.python.analysis.extraPaths, path)
              end
            end
          end
        end
      end
    end
  end

  return config
end

return {
  -- Return the configuration function for LSP setup
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
  filetypes = { "python" },
  on_attach = function(client, bufnr)
    -- When a buffer is attached to the pyright LSP server
    -- update Python environment settings if needed
    local function update_pyright_settings()
      local buf_path = vim.api.nvim_buf_get_name(0)
      local python_path, venv_dir = get_venv_python(buf_path)
      if not python_path or not is_executable(python_path) then
        python_path = get_system_python()
        venv_dir = nil
      end

      -- Update settings for this client
      if client.config.settings and client.config.settings.python then
        client.config.settings.python.pythonPath = python_path
        if venv_dir then
          client.config.settings.python.venvPath = vim.fn.fnamemodify(venv_dir, ":h")
        end
      end
    end

    -- Update settings when entering the buffer
    update_pyright_settings()
  end,
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
        typeCheckingMode = "basic" -- 可改为 "strict" 或 "off"
      }
    }
  },
  single_file_support = true,
  -- Define a function to update settings based on the current buffer
  root_dir = function(fname)
    local root_files = {
      "pyproject.toml",
      "setup.py",
      "setup.cfg",
      "requirements.txt",
      "Pipfile",
      "pyrightconfig.json",
      ".git"
    }
    return require("lspconfig.util").root_pattern(unpack(root_files))(fname) or vim.fn.getcwd()
  end,
  on_new_config = function(new_config, new_root_dir)
    -- Update the configuration when a new configuration is created
    local updated_config = get_pyright_config()
    new_config.settings = updated_config.settings
  end
}

