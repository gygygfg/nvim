-- MCP Hub 完整集成配置
-- 根据 MCP Hub 集成指南创建
-- 文件: config/mcphub_integration.lua

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
        add_mcp_prefix_to_tool_names = false, -- 添加 mcp__ 前缀（如 `@mcp__github`, `@mcp__neovim__list_issues`）
        show_result_in_chat = true,           -- 在聊天缓冲区直接显示工具结果

        -- MCP 资源配置
        make_vars = true,                     -- 将 MCP 资源转换为 #variables 供提示词使用

        -- MCP 提示词配置
        make_slash_commands = true,           -- 将 MCP 提示词添加为 /slash 命令
      }
    }
  }
end

-- 自定义工具组配置
function M.get_custom_tool_groups()
  return {
    groups = {
      ["github_pr_workflow"] = {
        description = "从 issue 到 PR 的 GitHub 操作流程",
        tools = {
          "neovim__read_multiple_files", "neovim__write_file", "neovim__edit_file",
          "github__list_issues", "github__get_issue", "github__get_issue_comments",
          "github__create_issue", "github__create_pull_request", "github__get_file_contents",
          "github__create_or_update_file", "github__search_code"
        },
      },
      ["web_research"] = {
        description = "网页研究和内容提取工作流",
        tools = {
          "context7__search", "context7__query",
          "crawl4ai__crawl", "crawl4ai__extract", "crawl4ai__summarize",
          "filesystem__read_file", "filesystem__write_file",
          "neovim__read_file", "neovim__write_file"
        },
      },
      ["code_analysis"] = {
        description = "代码分析和文档查询工作流",
        tools = {
          "context7__search", "context7__query",
          "neovim__read_file", "neovim__get_diagnostics",
          "filesystem__list_files", "filesystem__read_file"
        },
      },
      ["mcp_suite"] = {
        description = "所有 MCP 服务器的完整套件",
        tools = {
          "context7__search", "context7__query",
          "crawl4ai__crawl", "crawl4ai__extract", "crawl4ai__summarize",
          "github__list_issues", "github__get_issue", "github__create_issue",
          "filesystem__read_file", "filesystem__list_files", "filesystem__write_file",
          "neovim__read_file", "neovim__write_file", "neovim__get_buffer_content"
        },
      },
      ["development"] = {
        description = "开发工作流（文档、GitHub、编辑器）",
        tools = {
          "context7__search", "context7__query",
          "github__list_issues", "github__get_issue", "github__get_file_contents",
          "neovim__read_file", "neovim__write_file", "neovim__get_diagnostics"
        },
      },
    }
  }
end


-- 获取 MCP Hub 系统提示词
function M.get_mcphub_system_prompt()
  return [[
  ## MCP Hub 集成指南

  ### 核心概念
  MCP Hub 是一个 MCP（Model Context Protocol）服务器管理平台，为 CodeCompanion.nvim 提供统一的外部工具访问接口。通过集成，您可以在 Neovim 中直接使用各种 MCP 服务器的工具、资源和提示词。

  ### 使用方式

  #### 1. 工具访问的四种模式

  a. 通用 MCP 访问 (@mcp)
  @{mcp} 当前目录下有哪些文件？

  - 将所有可用 MCP 服务器添加到系统提示词
  - 为 LLM 提供 "@mcp" 工具组，包含 "use_mcp_tool" 和 "access_mcp_resource" 工具

  b. 服务器组访问
  neovim工具 读取 main.lua 文件
  github工具 创建一个 issue
  @{fetch} 获取这个网页

  - 访问特定服务器的所有工具
  - 组名取决于连接的 MCP 服务器

  c. 独立工具访问
  @{neovim__read_file} 显示配置文件
  @{fetch__fetch} 获取网页内容
  @{github__create_issue} 提交 bug 报告

  - 精细控制单个工具
  - 工具名格式："servername__toolname"

  d. 自定义工具组
  您可以使用预定义的工具组：
  - @{github_pr_workflow}: 从 issue 到 PR 的 GitHub 操作流程
  - @{web_research}: 网页研究和内容提取工作流
  - @{code_analysis}: 代码分析和文档查询工作流

  #### 2. 资源变量
  当 "make_vars = true" 时，MCP 资源可作为变量使用：
  修复文件中的诊断问题 #{mcp:neovim://diagnostics/buffer}
  分析当前缓冲区 #{mcp:neovim:buffer}

  #### 3. 斜杠命令
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
  1. 逐步启用功能：先启用 "make_tools = true"，熟悉后再添加 "make_vars" 和 "make_slash_commands"
  2. 安全配置：对敏感操作使用函数式自动批准，避免全局自动批准
  3. 工具发现：使用 MCP Hub UI 或 CodeCompanion 的工具补全来发现可用工具
  4. 服务器管理：通过 MCP Hub UI 管理服务器连接和配置
  5. 自定义工作流：根据项目需求创建自定义工具组，提高效率
  ]]
end

-- 获取完整的 MCP Hub 配置
function M.get_full_config()
  -- 导入自动批准配置模块
  local mcphub_auto_approve = require("config.mcphub_auto_approve")

  return {
    extension = M.get_mcphub_extension_config(),
    tool_groups = M.get_custom_tool_groups(),
    auto_approve = mcphub_auto_approve.get_config(),
    system_prompt = M.get_mcphub_system_prompt(),

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

return M
