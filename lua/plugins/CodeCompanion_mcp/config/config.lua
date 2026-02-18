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
    if keymaps and keymaps.codeCompanion then
      keymaps.codeCompanion()
    end
  end)
  if not keymap_success then
    vim.notify("加载 CodeCompanion 快捷键映射时出错：" .. tostring(err), vim.log.levels.ERROR)
  end

  -- 命令缩写
  vim.cmd([[cab cc CodeCompanion]])
  vim.cmd([[cab ccc CodeCompanionChat]])

  -- 确保聊天窗口模式切换的简单解决方案
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*CodeCompanion*",
    callback = function()
      -- 当进入 CodeCompanion 缓冲区时，切换到插入模式
      vim.defer_fn(function()
        vim.api.nvim_feedkeys("i", "n", true)
      end, 50)
    end,
  })

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
  local mcp_integration_success, mcp_integration = pcall(require, "mcp_integration")
  
  if not mcp_integration_success then
    -- 尝试带路径的模块名
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
  local custom_tools_success, custom_tools = pcall(require, "plugins.CodeCompanion_mcp.extensions.custom_mcp_tools")
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

  -- 为聊天窗口添加快捷键
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "codecompanion",
    callback = function()
      -- 添加全屏切换快捷键
      vim.keymap.set("n", "<C-f>", toggle_chat_fullscreen, {
        buffer = true,
        desc = "切换聊天窗口全屏显示"
      })

      -- 添加 ESC 退出全屏
      vim.keymap.set("n", "<Esc>", function()
        if vim.w.codecompanion_is_fullscreen then
          toggle_chat_fullscreen()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), "n", true)
        end
      end, { buffer = true, desc = "退出全屏或正常 ESC" })

      -- 添加 MCP 服务调用示例
      vim.keymap.set("n", "<leader>mc", function()
        -- 在聊天窗口中插入 MCP 调用示例
        local lines = {
          "",
          "# MCP 服务调用示例",
          "",
          "## Context7 示例（获取代码库文档）",
          "@{context7} Get React hooks documentation",
          "",
          "## Crawl4AI 示例（爬取网页内容）",
          "@{crawl4ai} Crawl https://example.com and extract main content",
          "",
          "## 组合使用示例",
          "1. 先获取官方文档：@{context7} Get Express.js middleware documentation",
          "2. 再获取最新教程：@{crawl4ai} Search for Express.js middleware tutorials",
          "",
          "## 手动触发",
          "- 在查询中添加 'use context7' 强制使用 Context7",
          "- 在查询中添加 'use crawl4ai' 强制使用 Crawl4AI",
          "- 在查询中添加 'use mcp' 使用所有可用的 MCP 服务",
          "",
        }

        -- 获取当前缓冲区
        local buf = vim.api.nvim_get_current_buf()
        local line_count = vim.api.nvim_buf_line_count(buf)

        -- 在缓冲区末尾插入示例
        for _, line in ipairs(lines) do
          vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, {line})
          line_count = line_count + 1
        end

        -- 移动到插入内容的开头
        vim.api.nvim_win_set_cursor(0, {line_count - #lines + 1, 0})

        vim.notify("已插入 MCP 服务调用示例，按 i 开始编辑", vim.log.levels.INFO)
      end, { buffer = true, desc = "插入 MCP 服务调用示例" })
    end,
  })
end

return M
