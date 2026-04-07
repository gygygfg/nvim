-- CodeCompanion 配置函数
-- 文件：CodeCompanion/config.lua

local M = {}

-- 全屏切换功能
local function toggle_chat_fullscreen()
  -- 获取当前窗口
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_win_get_buf(current_win)
  local buf_name = vim.api.nvim_buf_get_name(current_buf)

  -- 检查是否是 CodeCompanion 聊天窗口
  if not string.find(buf_name, "CodeCompanion") then
    return
  end

  -- 获取当前窗口配置
  local win_config = vim.api.nvim_win_get_config(current_win)

  -- 如果是浮动窗口，切换全屏
  if win_config.relative ~= "" then
    -- 当前是浮动窗口，切换到全屏
    local columns = vim.o.columns
    local lines = vim.o.lines

    -- 保存原始大小和位置
    local original_config = {
      width = win_config.width,
      height = win_config.height,
      col = win_config.col,
      row = win_config.row,
      is_fullscreen = false
    }

    -- 设置全屏
    vim.api.nvim_win_set_config(current_win, {
      relative = "editor",
      width = columns,
      height = lines,
      col = 0,
      row = 0,
      border = "none",
    })

    -- 保存原始配置到窗口变量
    vim.w.codecompanion_original_config = original_config
    vim.w.codecompanion_is_fullscreen = true
  else
    -- 当前可能是全屏或普通窗口
    if vim.w.codecompanion_is_fullscreen then
      -- 恢复原始配置
      local original_config = vim.w.codecompanion_original_config
      if original_config then
        vim.api.nvim_win_set_config(current_win, {
          relative = "editor",
          width = original_config.width,
          height = original_config.height,
          col = original_config.col,
          row = original_config.row,
          border = "rounded",
        })
      end
      vim.w.codecompanion_is_fullscreen = false
    else
      -- 如果不是全屏，切换到全屏
      local columns = vim.o.columns
      local lines = vim.o.lines

      -- 获取当前窗口位置和大小
      local wininfo = vim.fn.getwininfo(current_win)[1]
      local original_config = {
        width = wininfo.width,
        height = wininfo.height,
        col = wininfo.wincol - 1,
        row = wininfo.winrow - 1,
        is_fullscreen = false
      }

      -- 设置全屏
      vim.api.nvim_win_set_config(current_win, {
        relative = "editor",
        width = columns,
        height = lines,
        col = 0,
        row = 0,
        border = "none",
      })

      vim.w.codecompanion_original_config = original_config
      vim.w.codecompanion_is_fullscreen = true
    end
  end
end

-- 主配置函数
function M.setup(opts)
  -- 设置包路径，确保模块可以正确加载
  -- 使用基于家目录的动态路径
  local home_dir = vim.fn.expand("~")
  local current_dir = home_dir .. "/.config/nvim/lua/plugins.CodeCompanion"

  -- 将当前插件目录添加到包路径
  package.path = package.path .. ";" .. current_dir .. "/?.lua"
  package.path = package.path .. ";" .. current_dir .. "/?/init.lua"

  -- 调试信息（已注释）
  -- vim.notify("设置包路径，当前目录: " .. current_dir, vim.log.levels.DEBUG)

  -- 尝试初始化 MCP Hub，如果可用的话
  local mcphub_success, mcphub = pcall(require, "mcphub")
  if mcphub_success and mcphub then
    mcphub.setup({
      auto_approve = true,                              -- 自动批准所有 MCP 工具调用
      config_dir = vim.fn.expand("~/.config/nvim/mcp"), -- MCP 配置文件目录
    })
    -- vim.notify("✅ MCP Hub 初始化成功", vim.log.levels.INFO)
  else
    vim.notify("⚠️  MCP Hub 未找到，MCP 功能可能不可用", vim.log.levels.WARN)
    vim.notify("💡 请确保已安装 ravitemer/mcphub.nvim 插件", vim.log.levels.INFO)
  end

  -- Initialize the main plugin if available
  local ok, codecompanion = pcall(require, "codecompanion")
  if ok and codecompanion then
    codecompanion.setup(opts)
  else
    vim.notify("⚠️  CodeCompanion plugin not found", vim.log.levels.ERROR)
    return
  end

  -- 设置按键绑定，捕获可能的错误
  local keymap_success, err = pcall(function()
    local keymaps = require("core.keymaps")
    if keymaps and keymaps.codecompanion then
      keymaps.codecompanion().setup()
    end
  end)
  if not keymap_success then
    vim.notify("加载 CodeCompanion 快捷键映射时出错：" .. tostring(err), vim.log.levels.ERROR)
  end

  -- 命令缩写
  vim.cmd([[cab cc CodeCompanion]])
  vim.cmd([[cab ccc CodeCompanionChat]])

  vim.api.nvim_create_autocmd("BufLeave", {
    pattern = "*CodeCompanion*",
    callback = function()
      -- 当离开 CodeCompanion 缓冲区时，确保切换到正常模式
      local mode = vim.api.nvim_get_mode().mode
      if mode == "i" or mode == "ic" or mode == "ix" then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), "n", true)
      end
    end,
  })

  -- 自动命令：当打开 diff 窗口时，简化显示
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*Diff:*",
    callback = function()
      -- 可以在这里添加自定义的 diff 窗口行为
      vim.opt_local.conceallevel = 3
      vim.opt_local.wrap = false
    end,
  })

  -- 初始化 MCP 集成模块
  local mcp_integration_success, mcp_integration = false, nil

  -- 方法1：尝试使用 loadfile 加载
  local mcp_integration_path = current_dir .. "/mcp/mcp_integration.lua"
  mcp_integration_success, mcp_integration = pcall(function()
    local chunk, err = loadfile(mcp_integration_path)
    if not chunk then
      error("加载文件失败: " .. (err or "未知错误"))
    end
    return chunk()
  end)

  -- 方法2：如果方法1失败，尝试使用 require
  if not mcp_integration_success then
    mcp_integration_success, mcp_integration = pcall(require, "plugins.CodeCompanion.mcp.mcp_integration")
  end

  -- 方法3：如果方法2失败，尝试相对路径
  if not mcp_integration_success then
    mcp_integration_success, mcp_integration = pcall(require, "mcp.mcp_integration")
  end

  if mcp_integration_success and mcp_integration then
    local setup_success, setup_err = pcall(function()
      mcp_integration.setup()
    end)

    if setup_success then
      -- vim.notify("✅ MCP 集成模块初始化成功", vim.log.levels.INFO)
    else
      vim.notify("⚠️  MCP 集成模块初始化失败: " .. tostring(setup_err), vim.log.levels.WARN)
    end
  else
    vim.notify("⚠️  MCP 集成模块加载失败，但基本 MCP 功能仍然可用", vim.log.levels.WARN)
    vim.notify("💡 这不会影响 MCP 工具的基本功能，只是缺少一些高级集成特性", vim.log.levels.INFO)
  end

  -- 初始化动态工具管理器
  local dynamic_tool_manager_success, dynamic_tool_manager = pcall(require,
    "plugins.CodeCompanion.mcp.dynamic_tool_manager")
  if dynamic_tool_manager_success and dynamic_tool_manager then
    dynamic_tool_manager.setup()
    -- vim.notify("✅ 动态工具管理器初始化成功", vim.log.levels.INFO)
  else
    vim.notify("⚠️  动态工具管理器加载失败", vim.log.levels.WARN)
  end

  -- 初始化 MCP 工具配置
  local mcp_tools_config_success, mcp_tools_config = pcall(require, "plugins.CodeCompanion.config.mcp_tools_config")
  if mcp_tools_config_success and mcp_tools_config then
    mcp_tools_config.setup()
    -- vim.notify("✅ MCP 工具配置初始化成功", vim.log.levels.INFO)
  else
    vim.notify("⚠️  MCP 工具配置加载失败", vim.log.levels.WARN)
  end
end

return M
