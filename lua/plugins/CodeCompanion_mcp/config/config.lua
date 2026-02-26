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
  local current_dir = home_dir .. "/.config/nvim/lua/plugins/CodeCompanion_mcp"

  -- 将当前插件目录添加到包路径
  package.path = package.path .. ";" .. current_dir .. "/?.lua"
  package.path = package.path .. ";" .. current_dir .. "/?/init.lua"

  -- 调试信息（已注释）
  -- vim.notify("设置包路径，当前目录: " .. current_dir, vim.log.levels.DEBUG)

  -- 尝试初始化 MCP Hub，如果可用的话
  local mcphub_success, mcphub = pcall(require, "mcphub")
  if mcphub_success and mcphub then
    mcphub.setup({
      auto_approve = true, -- 自动批准所有 MCP 工具调用
      config_dir = vim.fn.expand("~/.config/nvim/mcp"), -- MCP 配置文件目录
    })
    vim.notify("✅ MCP Hub 初始化成功", vim.log.levels.INFO)
  else
    vim.notify("⚠️  MCP Hub 未找到，MCP 功能可能不可用", vim.log.levels.WARN)
    vim.notify("💡 请确保已安装 ravitemer/mcphub.nvim 插件", vim.log.levels.INFO)
  end

  -- Initialize the main plugin if available
  local plugin_success, codecompanion = pcall(require, "codecompanion")
  if plugin_success then
    codecompanion.setup(opts)
  else
    vim.notify("⚠️  未找到主 codecompanion.nvim 插件。请确保已安装。", vim.log.levels.WARN)
    vim.notify("💡  Install with: git clone https://github.com/olimorris/codecompanion.nvim ~/.local/share/nvim/lazy/codecompanion.nvim", vim.log.levels.INFO)
  end

  -- 设置按键绑定，捕获可能的错误
  local keymap_success, err = pcall(function()
    local keymaps = require("keymaps")
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
    mcp_integration_success, mcp_integration = pcall(require, "plugins.CodeCompanion_mcp.mcp.mcp_integration")
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
      vim.notify("✅ MCP 集成模块初始化成功", vim.log.levels.INFO)
    else
      vim.notify("⚠️  MCP 集成模块初始化失败: " .. tostring(setup_err), vim.log.levels.WARN)
    end
  else
    vim.notify("⚠️  MCP 集成模块加载失败，但基本 MCP 功能仍然可用", vim.log.levels.WARN)
    vim.notify("💡 这不会影响 MCP 工具的基本功能，只是缺少一些高级集成特性", vim.log.levels.INFO)
  end

  -- 加载自定义 MCP 工具扩展
  local custom_tools_success, custom_tools = false, nil

  -- 方法1：尝试使用 loadfile 加载
  local custom_tools_path = current_dir .. "/extensions/custom_mcp_tools.lua"
  custom_tools_success, custom_tools = pcall(function()
    local chunk, err = loadfile(custom_tools_path)
    if not chunk then
      error("加载文件失败: " .. (err or "未知错误"))
    end
    return chunk()
  end)

  -- 方法2：如果方法1失败，尝试使用 require
  if not custom_tools_success then
    custom_tools_success, custom_tools = pcall(require, "plugins.CodeCompanion_mcp.extensions.custom_mcp_tools")
  end

  -- 方法3：如果方法2失败，尝试相对路径
  if not custom_tools_success then
    custom_tools_success, custom_tools = pcall(require, "extensions.custom_mcp_tools")
  end
  if custom_tools_success and custom_tools then
    -- 获取扩展配置
    local extension_config = custom_tools.setup()

    -- 确保扩展配置被正确设置
    if extension_config then
      -- 确保 opts 不为 nil
      opts = opts or {}

      -- 将扩展配置合并到主配置中
      if not opts.extensions then
        opts.extensions = {}
      end

      opts.extensions["custom_mcp_tools"] = extension_config

      vim.notify("✅ 自定义 MCP 工具扩展加载成功", vim.log.levels.INFO)

      -- 显示可用的 MCP 工具
      if extension_config.tools then
        local tool_count = 0
        for name, _ in pairs(extension_config.tools) do
          tool_count = tool_count + 1
        end
        vim.notify("🔧 加载了 " .. tool_count .. " 个 MCP 工具", vim.log.levels.INFO)
      end
    end
  else
    vim.notify("⚠️  自定义 MCP 工具扩展加载失败: " .. tostring(custom_tools), vim.log.levels.WARN)
  end
end

return M
