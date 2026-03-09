-- MCP Hub 动态集成配置
-- 工具组和工具定义将通过 MCP Hub 动态生成

local M = {}

-- MCP Hub 扩展配置
function M.get_mcphub_extension_config()
  return {
    mcphub = {
      callback = "mcphub.extensions.codecompanion",
      opts = {
        -- MCP 工具配置
        make_tools = true,                    -- 从 MCP 服务器创建独立工具 (@server__tool) 和服务器组 (@server)
        show_server_tools_in_chat = true,     -- 在聊天补全中显示独立工具（当 make_tools=true 时）
        add_mcp_prefix_to_tool_names = true,  -- 添加 mcp__ 前缀以避免冲突（如 `@mcp__github`, `@mcp__neovim__list_issues`）
        show_result_in_chat = true,           -- 在聊天缓冲区直接显示工具结果
        
        -- 组名冲突解决方案
        server_group_prefix = "mcp_",         -- 为服务器组添加前缀（如 @mcp_context7, @mcp_github）
        skip_server_groups = false,           -- 是否跳过创建服务器组（设置为 true 可避免冲突）

        -- MCP 资源配置
        make_vars = true,                     -- 将 MCP 资源转换为 #variables 供提示词使用

        -- MCP 提示词配置
        make_slash_commands = true,           -- 将 MCP 提示词添加为 /slash 命令

        -- 动态工具发现
        auto_discover_servers = true,         -- 自动发现新的 MCP 服务器
        refresh_interval = 300,               -- 每5分钟刷新一次工具列表（秒）
        cache_tools = true,                   -- 缓存工具定义以提高性能
      }
    }
  }
end

-- 动态生成工具组配置
function M.get_dynamic_tool_groups()
  -- 这个函数将在运行时调用，从 MCP Hub 获取当前可用的工具
  -- 并动态生成工具组配置
  
  -- 返回空表，表示工具组将由 MCP Hub 动态生成
  return {
    groups = {}
  }
end

-- 获取 MCP Hub 系统提示词
function M.get_mcphub_system_prompt()
  return [[
  ## MCP Hub 动态集成指南

  ### 核心概念
  MCP Hub 是一个 MCP（Model Context Protocol）服务器管理平台，为 CodeCompanion.nvim 提供统一的外部工具访问接口。
  通过集成，您可以在 Neovim 中直接使用各种 MCP 服务器的工具、资源和提示词。

  ### 动态工具发现
  MCP Hub 会自动发现和管理所有可用的 MCP 服务器。无需手动配置工具定义。

  ### 使用方式

  #### 1. 通用 MCP 访问 (@mcp)
  @{mcp} 当前目录下有哪些文件？

  - 将所有可用 MCP 服务器添加到系统提示词
  - 为 LLM 提供 "@mcp" 工具组，包含 "use_mcp_tool" 和 "access_mcp_resource" 工具

  #### 2. 服务器组访问（带前缀）
  @{mcp_neovim} 读取 main.lua 文件
  @{mcp_github} 创建一个 issue
  @{mcp_crawl4ai} 获取这个网页

  - 访问特定服务器的所有工具
  - 组名格式：mcp_ + 服务器名称（如 mcp_neovim, mcp_github）

  #### 3. 独立工具访问（带前缀）
  @{mcp__neovim__read_file} 显示配置文件
  @{mcp__fetch__fetch} 获取网页内容
  @{mcp__github__create_issue} 提交 bug 报告

  - 精细控制单个工具
  - 工具名格式："mcp__servername__toolname"

  #### 4. 动态工具组
  MCP Hub 会根据当前可用的服务器自动生成工具组。
  使用 @{mcp} 查看所有可用工具。

  #### 5. 资源变量
  当 "make_vars = true" 时，MCP 资源可作为变量使用：
  修复文件中的诊断问题 #{mcp:neovim://diagnostics/buffer}
  分析当前缓冲区 #{mcp:neovim:buffer}

  #### 6. 斜杠命令
  当 "make_slash_commands = true" 时，MCP 提示词可作为斜杠命令：
  /mcp:code_review
  /mcp:explain_function
  /mcp:generate_tests

  ### 内置服务器功能
  MCP Hub 包含强大的内置服务器：
  - @neovim：文件操作、终端、LSP 功能
  - @mcphub：服务器管理功能
  - @github：GitHub API 集成
  - @fetch：网页获取功能

  ### 最佳实践
  1. 动态发现：MCP Hub 会自动发现新服务器，无需手动配置
  2. 安全配置：对敏感操作使用函数式自动批准，避免全局自动批准
  3. 工具发现：使用 MCP Hub UI 或 CodeCompanion 的工具补全来发现可用工具
  4. 服务器管理：通过 MCP Hub UI 管理服务器连接和配置
  5. 性能优化：工具定义会被缓存，定期刷新
  ]]
end

-- 获取完整的 MCP Hub 配置
function M.get_full_config()
  -- 尝试导入自动批准配置模块
  local mcphub_auto_approve
  local success, err = pcall(function()
    mcphub_auto_approve = require("plugins.CodeCompanion_mcp.config.mcphub_auto_approve")
  end)
  
  if not success then
    -- 如果无法加载，使用简化版本
    print("警告: 无法加载 mcphub_auto_approve:", err)
    mcphub_auto_approve = {
      get_config = function()
        return {
          auto_approve = false,
          default_auto_approve_patterns = {},
          manual_approval_patterns = {},
          rules = {}
        }
      end
    }
  end

  return {
    extension = M.get_mcphub_extension_config(),
    tool_groups = M.get_dynamic_tool_groups(),
    auto_approve = mcphub_auto_approve.get_config(),
    system_prompt = M.get_mcphub_system_prompt(),

    -- 动态配置选项
    dynamic_config = {
      enabled = true,
      auto_refresh = true,
      cache_duration = 300, -- 5分钟
      on_server_change = "auto_update", -- 服务器变化时自动更新
    },

    -- 故障排除配置
    troubleshooting = {
      -- 已知问题：变量描述换行符错误
      fix_newline_issue = true,
      -- 解决方案：更新 MCP Hub 到最新版本
      require_mcphub_update = true,
    },

    -- 更新与维护配置
    maintenance = {
      update_command = ":Lazy update",
      mcphub_ui_url = "http://localhost:3000",
      mcphub_ui_credentials = { username = "admin", password = "admin123" },
      check_logs_command = ":messages",
    }
  }
end

-- 动态工具发现函数
function M.discover_mcp_tools()
  -- 这个函数会被定期调用，从 MCP Hub 发现新工具
  -- 返回当前可用的工具列表
  
  -- 在实际实现中，这里会调用 MCP Hub API 获取工具列表
  -- 目前返回空表，表示由 MCP Hub 自动处理
  return {}
end

-- 工具组生成函数
function M.generate_tool_groups(available_tools)
  -- 根据可用工具动态生成工具组
  -- available_tools: 从 MCP Hub 获取的工具列表
  
  local groups = {}
  
  -- 这里可以根据工具类型、服务器等自动生成工具组
  -- 例如：按服务器分组、按功能分组等
  
  return {
    groups = groups
  }
end

return M
