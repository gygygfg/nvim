local M = {}

-- 导入动态工具管理器
local dynamic_tool_manager = require("config.CodeCompanion.mcp.dynamic_tool_manager")

-- 获取动态系统提示
function M.get_dynamic_system_prompt()
  return dynamic_tool_manager.get_dynamic_system_prompt()
end

-- 获取工具配置
function M.get_tools_config()
  -- 获取动态工具配置
  local dynamic_config = dynamic_tool_manager.get_dynamic_tool_config()

  return {
    system_prompt = M.get_dynamic_system_prompt(),
    tools = dynamic_config.tools,
    groups = dynamic_config.groups,
    default_tools = dynamic_config.default_tools,
    tool_opts = {
      system_prompt = {
        prompt = M.get_dynamic_system_prompt()
      }
    }
  }
end

-- 初始化函数
function M.setup()
  -- 初始化动态工具管理器
  dynamic_tool_manager.setup()

  return M
end

return M

