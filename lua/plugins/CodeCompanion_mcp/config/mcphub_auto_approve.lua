-- MCP Hub 动态自动批准配置
-- 支持动态发现的工具自动批准

local M = {}

-- 获取自动批准配置
function M.get_config()
  return {
    -- 服务器配置
    servers = {},

    -- 全局自动批准
    auto_approve = false,

    -- 动态工具自动批准函数
    auto_approve_function = function(params)
      -- 当 CodeCompanion 自动工具模式启用时自动批准
      if vim.g.codecompanion_auto_tool_mode == true then
        return true
      end

      -- 自动批准只读操作
      local read_only_tools = {
        "read", "get", "list", "search", "query", "fetch",
        "extract", "crawl", "summarize", "diagnostics"
      }
      
      for _, prefix in ipairs(read_only_tools) do
        if params.tool_name:find(prefix) then
          return true
        end
      end

      -- 阻止危险操作
      local dangerous_tools = {
        "delete", "remove", "rm", "format", "reset", "clear",
        "shutdown", "stop", "kill", "terminate"
      }
      
      for _, keyword in ipairs(dangerous_tools) do
        if params.tool_name:find(keyword) then
          return "危险操作需要手动批准: " .. params.tool_name
        end
      end

      -- 默认显示确认提示
      return false
    end,

    -- 动态默认自动批准的工具模式
    default_auto_approve_patterns = {
      -- Neovim 相关工具（只读）
      "neovim__read",
      "neovim__get",
      "neovim__list",
      "neovim__diagnostics",

      -- GitHub 相关工具（只读操作）
      "github__get",
      "github__list",
      "github__search",

      -- Context7 相关工具
      "context7__",

      -- Crawl4AI 相关工具（只读操作）
      "crawl4ai__crawl",
      "crawl4ai__extract",
      "crawl4ai__summarize",
    },

    -- 需要手动批准的工具模式
    manual_approval_patterns = {
      -- 写操作工具
      "neovim__write",
      "neovim__edit",
      "neovim__create",
      "neovim__delete",

      -- GitHub 写操作
      "github__create",
      "github__update",
      "github__delete",
      "github__push",

      -- 系统命令执行
      "cmd_runner",
    },

    -- 动态自动批准规则
    rules = {
      {
        condition = function(params)
          -- 如果工具匹配默认自动批准模式
          for _, pattern in ipairs(M.get_config().default_auto_approve_patterns) do
            if params.tool_name:find(pattern) then
              return true
            end
          end
          return false
        end,
        action = "auto_approve",
        message = "工具匹配自动批准模式"
      },
      {
        condition = function(params)
          -- 如果工具匹配手动批准模式
          for _, pattern in ipairs(M.get_config().manual_approval_patterns) do
            if params.tool_name:find(pattern) then
              return true
            end
          end
          return false
        end,
        action = "manual_approval",
        message = "工具需要手动批准"
      },
      {
        condition = function(params)
          -- 如果启用了 CodeCompanion 自动工具模式
          return vim.g.codecompanion_auto_tool_mode == true
        end,
        action = "auto_approve",
        message = "自动工具模式已启用"
      },
      {
        condition = function(params)
          -- 动态工具：如果是新发现的工具，默认需要手动批准
          local is_new_tool = params.tool_name:find("__") and not params.tool_name:find("neovim__") and not params.tool_name:find("github__")
          return is_new_tool
        end,
        action = "manual_approval",
        message = "新发现的工具需要手动批准"
      }
    }
  }
end

-- 检查工具是否需要自动批准
function M.should_auto_approve(params)
  local config = M.get_config()

  -- 首先检查全局自动批准设置
  if config.auto_approve then
    return true, "全局自动批准已启用"
  end

  -- 检查函数式自动批准
  if config.auto_approve_function then
    local result = config.auto_approve_function(params)
    if result == true then
      return true, "函数式自动批准通过"
    elseif result == false then
      return false, "函数式自动批准拒绝"
    elseif type(result) == "string" then
      return false, result -- 返回拒绝消息
    end
  end

  -- 检查规则
  for _, rule in ipairs(config.rules) do
    if rule.condition(params) then
      if rule.action == "auto_approve" then
        return true, rule.message
      elseif rule.action == "manual_approval" then
        return false, rule.message
      end
    end
  end

  -- 默认需要手动批准
  return false, "需要手动批准"
end

-- 获取工具批准状态消息
function M.get_approval_message(params)
  local should_approve, message = M.should_auto_approve(params)

  if should_approve then
    return "✅ " .. message
  else
    return "❌ " .. message
  end
end

-- 设置自动批准模式
function M.set_auto_approve_mode(enabled)
  vim.g.codecompanion_auto_tool_mode = enabled
  if enabled then
    vim.notify("已启用 CodeCompanion 自动工具模式", vim.log.levels.INFO)
  else
    vim.notify("已禁用 CodeCompanion 自动工具模式", vim.log.levels.INFO)
  end
end

-- 切换自动批准模式
function M.toggle_auto_approve_mode()
  local current = vim.g.codecompanion_auto_tool_mode or false
  M.set_auto_approve_mode(not current)
end

-- 动态添加工具批准规则
function M.add_dynamic_approval_rule(tool_pattern, action, message)
  local config = M.get_config()
  
  table.insert(config.rules, {
    condition = function(params)
      return params.tool_name:find(tool_pattern)
    end,
    action = action,
    message = message
  })
  
  vim.notify("已添加动态批准规则: " .. tool_pattern, vim.log.levels.INFO)
end

-- 从 MCP Hub 发现工具并更新批准规则
function M.update_approval_rules_from_mcphub()
  -- 这个函数会从 MCP Hub 获取工具列表
  -- 并根据工具类型自动添加批准规则
  
  -- 在实际实现中，这里会调用 MCP Hub API
  -- 目前只是示例
  
  vim.notify("正在从 MCP Hub 更新批准规则...", vim.log.levels.INFO)
  
  -- 示例：为常见工具类型添加规则
  local common_rules = {
    {"__read", "auto_approve", "只读工具自动批准"},
    {"__get", "auto_approve", "获取工具自动批准"},
    {"__list", "auto_approve", "列表工具自动批准"},
    {"__create", "manual_approval", "创建工具需要手动批准"},
    {"__delete", "manual_approval", "删除工具需要手动批准"},
    {"__write", "manual_approval", "写入工具需要手动批准"},
  }
  
  for _, rule in ipairs(common_rules) do
    M.add_dynamic_approval_rule(rule[1], rule[2], rule[3])
  end
  
  vim.notify("批准规则更新完成", vim.log.levels.INFO)
end

return M
