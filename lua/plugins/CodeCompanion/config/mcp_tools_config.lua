local M = {}

-- 动态生成系统提示
function M.get_dynamic_system_prompt()
  return [[## MCP 工具使用指南

  MCP 工具通过 MCP Hub 动态发现和管理。以下是可用的 MCP 服务器和正确的使用方式。

  ### 重要：没有名为 "mcp" 的服务器
  不要尝试调用 @{mcp} 或使用 "mcp" 作为服务器名称，这会失败。

  ### 可用的 MCP 服务器
  使用以下服务器名称（注意大小写和连字符）：
  - **context7**: Context7 代码库文档服务
  - **web-scout**: 网页搜索和内容提取服务（工具组: @{web_scout}）
  - **github**: GitHub 仓库管理服务（工具组: @{github}）
  - **neovim**: Neovim 编辑器操作服务（工具组: @{neovim}）
  - **chrome-devtools**: Chrome DevTools 浏览器自动化服务（工具组: @{chrome_devtools}）
  - **mcphub**: MCP Hub 服务器管理服务（工具组: @{mcphub}）

  ### 正确的使用方式

  #### 方式1：使用 @{use_mcp_tool} 工具（推荐）
  这是最可靠的方式，直接调用 MCP 服务器工具。

  格式：
  ```
  use_mcp_tool server_name tool_name {参数}
  ```

  示例：
  - `use_mcp_tool context7 query-docs {libraryId: "/python/docs", query: "How to use lists"}`
  - `use_mcp_tool github list_issues {owner: "yourname", repo: "yourrepo"}`
  - `use_mcp_tool web-scout UrlContentExtractor {url: "https://example.com"}`

  #### 方式2：使用服务器工具组
  通过工具组访问特定服务器的所有工具。

  格式：
  ```
  @{server_group} [查询内容]
  ```

  示例：
  - `@{github} List my repositories`
  - `@{neovim} Get current buffer content`
  - `@{web_scout} Search for latest news`
  - `@{context7} Search for Python documentation`

  注意：工具组名称使用下划线（如 web_scout），但实际服务器名称是连字符（web-scout）。

  #### 方式3：直接调用独立工具
  直接调用特定工具（需要知道准确的工具名称）。

  格式：
  ```
  server_name__tool_name {参数}
  ```

  示例：
  - `web-scout__UrlContentExtractor {url: "https://example.com"}`
  - `github__create_issue {owner: "yourname", repo: "yourrepo", title: "Bug report"}`
  - `neovim__read_file {path: "main.lua"}`

  注意：工具名中的服务器部分使用实际名称（带连字符）。

  ### 快速开始
  1. 首先查看可用的服务器：
  `mcphub__get_current_servers {}`

  2. 测试 GitHub 工具：
  `@{github} List my repositories`

  3. 测试网页搜索：
  `use_mcp_tool web-scout DuckDuckGoWebSearch {query: "test", maxResults: 3}`

  4. 测试文档查询：
  `use_mcp_tool context7 query-docs {libraryId: "/python/docs", query: "lists"}`

  ### 故障排除
  如果遇到 "Server not found" 错误：
  1. 检查服务器名称是否正确（注意连字符）
  2. 使用 @{use_mcp_tool} 而不是尝试调用 @{mcp}
  3. 查看可用服务器：`mcphub__get_current_servers {}`

  记住：没有 "mcp" 服务器，只有上面列出的具体服务器。]]
end

-- 获取工具配置
function M.get_tools_config()
  return {
    system_prompt = M.get_dynamic_system_prompt(),
    tools = {
      use_mcp_tool = {
        description = "calls tools on MCP servers.",
        parameters = {
          type = "object",
          required = {"server_name", "tool_name", "tool_input"},
          additionalProperties = false,
          properties = {
            tool_name = {
              description = "Name of the tool to call.",
              type = "string"
            },
            server_name = {
              description = "Name of the server to call the tool on. Must be from one of the available servers.",
              type = "string"
            },
            tool_input = {
              type = "object",
              description = "Input object for the tool call",
              additionalProperties = false
            }
          }
        }
      }
    },
    groups = {
      mcp = {
        name = "MCP 工具",
        description = "MCP 服务器工具组",
        tools = {"use_mcp_tool"}
      }
    },
    default_tools = {"use_mcp_tool"},
    tool_opts = {
      system_prompt = {
        prompt = M.get_dynamic_system_prompt()
      }
    }
  }
end

return M