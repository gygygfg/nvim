-- nvm_init.lua
-- NVM 环境初始化 for Neovim

local M = {}

-- 检查并获取 NVM 管理的 Node 路径
local function get_nvm_node_info()
  local home = os.getenv("HOME")
  if not home then
    return nil
  end
  
  local nvm_dir = home .. "/.nvm"
  
  -- 方法1: 直接从 NVM 版本目录查找
  local versions_dir = nvm_dir .. "/versions/node"
  
  -- 查找所有版本并获取最新
  local find_cmd = string.format(
    "find '%s' -maxdepth 1 -type d -name 'v*' 2>/dev/null | sort -V | tail -1",
    versions_dir
  )
  
  local handle = io.popen(find_cmd)
  if not handle then
    return nil
  end
  
  local latest_dir = handle:read("*l")
  handle:close()
  
  if not latest_dir then
    -- 方法2: 尝试使用 nvm which current 命令
    local nvm_cmd = string.format(
      "source '%s/nvm.sh' 2>/dev/null && nvm which current 2>/dev/null",
      nvm_dir
    )
    
    local nvm_handle = io.popen(nvm_cmd)
    if nvm_handle then
      latest_dir = nvm_handle:read("*l")
      nvm_handle:close()
      
      if latest_dir then
        -- 提取目录路径（去掉 /bin/node 部分）
        latest_dir = latest_dir:gsub("/bin/node$", "")
      end
    end
  end
  
  if latest_dir then
    local bin_dir = latest_dir .. "/bin"
    
    -- 验证 bin 目录存在
    local stat = vim.loop.fs_stat(bin_dir)
    if stat then
      return {
        bin_dir = bin_dir,
        version_dir = latest_dir,
        node_path = bin_dir .. "/node",
        npm_path = bin_dir .. "/npm"
      }
    end
  end
  
  return nil
end

-- 设置环境变量
local function setup_environment(node_info)
  if not node_info then
    return false
  end
  
  -- 添加 bin 目录到 PATH
  local current_path = vim.env.PATH or ""
  if not current_path:match(node_info.bin_dir) then
    vim.env.PATH = node_info.bin_dir .. ":" .. current_path
  end
  
  -- 设置 NVM_DIR 环境变量（如果需要）
  vim.env.NVM_DIR = os.getenv("HOME") .. "/.nvm"
  
  return true
end

-- 验证设置
local function verify_setup()
  -- 检查 node 命令
  local node_check = io.popen("which node 2>/dev/null")
  if not node_check then
    return false, "Failed to check node command"
  end
  
  local node_path = node_check:read("*l")
  node_check:close()
  
  if not node_path then
    return false, "Node command not found in PATH"
  end
  
  -- 检查 node 版本
  local version_check = io.popen("node --version 2>/dev/null")
  if not version_check then
    return false, "Failed to check node version"
  end
  
  local version = version_check:read("*l")
  version_check:close()
  
  if not version then
    return false, "Failed to get node version"
  end
  
  return true, string.format("Node.js %s at %s", version, node_path)
end

-- 主设置函数
function M.setup()
  vim.schedule(function()
    -- 获取 Node 信息
    local node_info = get_nvm_node_info()
    
    if not node_info then
      vim.notify("No NVM-managed Node.js found. Using system Node if available.", 
                vim.log.levels.WARN)
      
      -- 检查系统 Node
      local success, msg = verify_setup()
      if success then
        vim.notify("Using system: " .. msg, vim.log.levels.INFO)
      end
      return
    end
    
    -- 设置环境
    local env_success = setup_environment(node_info)
    if not env_success then
      vim.notify("Failed to setup Node.js environment", vim.log.levels.ERROR)
      return
    end
    
    -- 验证设置
    local success, msg = verify_setup()
    if success then
      vim.notify("NVM environment: " .. msg, vim.log.levels.INFO)
    else
      vim.notify("Setup completed but verification failed: " .. msg, 
                vim.log.levels.WARN)
    end
  end)
end

-- 手动重新加载
function M.reload()
  vim.notify("Reloading NVM environment...", vim.log.levels.INFO)
  M.setup()
end

-- 获取当前 Node 信息
function M.info()
  local node_info = get_nvm_node_info()
  if node_info then
    return {
      bin_dir = node_info.bin_dir,
      version_dir = node_info.version_dir,
      node_path = node_info.node_path,
      npm_path = node_info.npm_path
    }
  end
  return nil
end

return M