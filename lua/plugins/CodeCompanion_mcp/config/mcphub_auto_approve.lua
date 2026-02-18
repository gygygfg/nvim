-- MCP Hub 自动批准配置集成
-- 文件: config/mcphub_auto_approve.lua

local M = {}

-- 获取自动批准配置
function M.get_config()
  return {
    -- 服务器配置
    servers = {},
    
    -- 全局自动批准
    auto_approve = false,
    
    -- 函数式自动批准
    auto_approve_function = function(params)
      -- 当 CodeCompanion 自动工具模式启用时自动批准
      if vim.g.codecompanion_auto_tool_mode == true then
        return true
      end
      
      -- 自动批准 GitHub issue 读取
      if params.server_name == "github" and params.tool_name == "get_issue" then
        return true
      end
      
      -- 自动批准文件读取操作
      if params.server_name == "filesystem" and params.tool_name == "read_file" then
        return true
      end
      
      -- 自动批准 Neovim 缓冲区操作
      if params.server_name == "neovim" and 
         (params.tool_name == "read_file" or params.tool_name == "get_buffer_content") then
        return true
      end
      
      -- 阻止访问私有仓库
      if params.arguments and params.arguments.repo == "private" then
        return "您不能访问我的私有仓库"
      end
      
      -- 默认显示确认提示
      return false
    end,
    
    -- 默认自动批准的工具列表
    default_auto_approve_tools = {
      -- Neovim 相关工具
      "neovim__read_file",
      "neovim__get_buffer_content",
      "neovim__list_buffers",
      "neovim__get_diagnostics",
      
      -- 文件系统相关工具
      "filesystem__read_file",
      "filesystem__list_files",
      "filesystem__stat",
      
      -- GitHub 相关工具（只读操作）
      "github__get_issue",
      "github__list_issues",
      "github__get_issue_comments",
      "github__get_file_contents",
      "github__search_code",
      
      -- Context7 相关工具
      "context7__search",
      "context7__query",
      
      -- Crawl4AI 相关工具（只读操作）
      "crawl4ai__crawl",
      "crawl4ai__extract",
      "crawl4ai__summarize",
    },
    
    -- 需要手动批准的工具列表
    manual_approval_tools = {
      -- 写操作工具
      "neovim__write_file",
      "neovim__edit_file",
      "filesystem__write_file",
      "filesystem__delete_file",
      "filesystem__create_directory",
      
      -- GitHub 写操作
      "github__create_issue",
      "github__create_pull_request",
      "github__create_or_update_file",
      "github__delete_file",
      
      -- 系统命令执行
      "cmd_runner",
    },
    
    -- 自动批准规则
    rules = {
      {
        condition = function(params)
          -- 如果工具在默认自动批准列表中
          for _, tool in ipairs(M.get_config().default_auto_approve_tools) do
            if params.tool_name == tool then
              return true
            end
          end
          return false
        end,
        action = "auto_approve",
        message = "工具在自动批准列表中"
      },
      {
        condition = function(params)
          -- 如果工具在手动批准列表中
          for _, tool in ipairs(M.get_config().manual_approval_tools) do
            if params.tool_name == tool then
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

return M