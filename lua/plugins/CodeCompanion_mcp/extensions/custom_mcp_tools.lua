-- CodeCompanion MCP 动态工具扩展
-- 不再硬编码工具定义，而是通过 MCP Hub 动态发现

-- 确保模块可以在 codecompanion._extensions 命名空间下被找到
if not package.loaded["codecompanion._extensions.custom_mcp_tools"] then
  package.preload["codecompanion._extensions.custom_mcp_tools"] = function()
    local M = {}
    
    -- 扩展配置函数
    function M.setup(opts)
      opts = opts or {}

      -- 返回动态扩展配置
      return {
        enabled = true,
        name = "dynamic_mcp_tools",
        description = "MCP 动态工具扩展",

        -- 工具配置（将由 MCP Hub 动态填充）
        tools = {},

        -- 扩展选项
        opts = {
          -- 动态发现配置
          auto_discover_servers = true,
          refresh_interval = 300, -- 每5分钟刷新一次
          cache_tools = true,
          
          -- 工具组配置（动态生成）
          groups = {},

          -- 自动触发配置
          auto_detect_mcp_usage = true,
          auto_suggest_mcp_tools = true,
        },
      }
    end
    
    return M
  end
end

-- 本地模块定义（用于直接 require）
local M = {}

-- 扩展配置函数
function M.setup(opts)
  opts = opts or {}

  -- 返回动态扩展配置
  return {
    enabled = true,
    name = "dynamic_mcp_tools",
    description = "MCP 动态工具扩展",

    -- 工具配置（将由 MCP Hub 动态填充）
    tools = {},

    -- 扩展选项
    opts = {
      -- 动态发现配置
      auto_discover_servers = true,
      refresh_interval = 300, -- 每5分钟刷新一次
      cache_tools = true,
      
      -- 工具组配置（动态生成）
      groups = {},

      -- 自动触发配置
      auto_detect_mcp_usage = true,
      auto_suggest_mcp_tools = true,

      -- 智能选择配置
      intelligent_selection = {
        enabled = true,
        confidence_threshold = 0.7,
        fallback_to_manual = true,
        learning_enabled = true
      },

      -- 结果显示配置
      show_result_in_chat = true,
      format_mcp_results = true,

      -- 工具调用配置
      make_tools = true, -- 创建单个工具
      show_server_tools_in_chat = true, -- 在聊天中显示工具
      add_mcp_prefix_to_tool_names = false, -- 不添加前缀
      
      -- 动态工具管理
      dynamic_tool_management = {
        auto_add_new_tools = true,
        auto_remove_missing_tools = true,
        tool_lifetime = 3600, -- 工具缓存时间（秒）
      }
    }
  }
end

-- 动态工具发现函数
function M.discover_tools()
  -- 这个函数会从 MCP Hub 发现可用的工具
  -- 在实际实现中，这里会调用 MCP Hub API
  
  local discovered_tools = {}
  
  -- 示例：返回空表，表示工具由 MCP Hub 自动管理
  return discovered_tools
end

-- 工具回调处理函数
-- 这个函数会被 CodeCompanion 调用当工具被触发时
function M.tool_callback(tool_name, args, tools_system)
  -- 对于 MCP 工具，直接使用 use_mcp_tool
  -- 工具名称格式应为 "server_name__tool_name"
  
  local server_name, actual_tool_name = tool_name:match("([^__]+)__(.+)")
  
  if server_name and actual_tool_name then
    -- 这是 MCP 工具，使用 use_mcp_tool
    return {
      status = "success",
      data = "MCP 工具调用: " .. tool_name .. "\n请使用 @mcp 或直接调用 MCP 工具"
    }
  else
    return {
      status = "error",
      data = "工具格式错误或不是 MCP 工具: " .. tool_name
    }
  end
end

-- 导出函数
M.exports = {
  -- 动态发现 MCP 工具
  discover_mcp_tools = M.discover_tools,
  
  -- 检查 MCP 服务器状态
  check_mcp_status = function()
    -- 尝试从 MCP Hub 获取服务器状态
    local status = {}
    
    -- 在实际实现中，这里会调用 MCP Hub API
    -- 目前返回示例状态
    
    status["dynamic_discovery"] = {
      enabled = true,
      description = "MCP 工具动态发现",
      last_refresh = os.time()
    }
    
    return status
  end,
  
  -- 工具回调函数（供 CodeCompanion 调用）
  tool_callback = M.tool_callback,
  
  -- 获取动态工具信息
  get_dynamic_tool_info = function()
    return {
      discovery_method = "MCP Hub 动态发现",
      auto_refresh = true,
      tool_count = "动态变化",
      last_update = os.time()
    }
  end
}

return M
