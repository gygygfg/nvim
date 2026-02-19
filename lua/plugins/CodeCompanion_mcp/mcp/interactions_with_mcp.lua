-- CodeCompanion 交互策略配置 - 包含 MCP 工具
-- 文件：CodeCompanion/interactions_with_mcp.lua
-- 基础配置 + MCP 工具集成

local M = {}

-- 导入基础配置
local base_config = require("plugins.CodeCompanion_mcp.core.interactions_base").config

-- 导入 MCP 工具配置
local mcp_config = require("plugins.CodeCompanion_mcp.config.mcp_tools_config")
local mcp_tools_config = mcp_config.get_tools_config()

-- 导入上下文管理器
local context_manager = require("plugins.CodeCompanion_mcp.config.context_manager")

-- 辅助函数：从文本中提取指定章节
local function extract_section(text, start_marker, end_marker)
  if not text or not start_marker then
    return nil
  end

  local start_pos = string.find(text, start_marker, 1, true)
  if not start_pos then
    return nil
  end

  local end_pos
  if end_marker then
    end_pos = string.find(text, end_marker, start_pos + 1, true)
  end

  if end_pos then
    return string.sub(text, start_pos, end_pos - 1)
  else
    return string.sub(text, start_pos)
  end
end

-- 深度合并配置
local function deep_merge_configs(base, mcp)
  local merged = vim.deepcopy(base)

  -- 1. 智能合并工具配置（避免覆盖基础工具）
  if mcp.tools then
    for tool_name, tool_config in pairs(mcp.tools) do
      -- 检查是否是基础工具
      local is_base_tool = false
      local base_tools = {
        "read_file", "create_file", "delete_file", "insert_edit_into_file",
        "cmd_runner", "fetch_webpage", "grep_search", "list_code_usages",
        "file_search", "get_changed_files"
      }

      for _, base_tool in ipairs(base_tools) do
        if tool_name == base_tool then
          is_base_tool = true
          break
        end
      end

      -- 如果不是基础工具，或者基础工具中没有定义，则添加
      if not is_base_tool or not merged.chat.tools[tool_name] then
        merged.chat.tools[tool_name] = tool_config
      else
        -- 如果是基础工具且已存在，可以记录日志但不覆盖
        if os.getenv("CODECOMPANION_DEBUG") then
          print("跳过重复的基础工具定义:", tool_name)
        end
      end
    end
  end

  -- 2. 智能合并工具组配置（避免重复）
  if mcp.groups then
    for group_name, group_config in pairs(mcp.groups) do
      -- 检查是否是基础工具组
      local is_base_group = false
      local base_groups = {
        "files"  -- 基础配置中的文件操作工具组
      }

      for _, base_group in ipairs(base_groups) do
        if group_name == base_group then
          is_base_group = true
          break
        end
      end

      -- 如果不是基础工具组，或者基础工具组中没有定义，则添加
      if not is_base_group or not merged.chat.tools.groups[group_name] then
        merged.chat.tools.groups[group_name] = tool_config
      else
        -- 如果是基础工具组且已存在，可以记录日志但不覆盖
        if os.getenv("CODECOMPANION_DEBUG") then
          print("跳过重复的基础工具组定义:", group_name)
        end
      end
    end
  end

  -- 3. 合并默认工具列表（智能去重）
  if mcp.default_tools then
    for _, mcp_tool in ipairs(mcp.default_tools) do
      local exists = false
      for _, existing_tool in ipairs(merged.chat.tools.opts.default_tools) do
        if existing_tool == mcp_tool then
          exists = true
          break
        end
      end

      if not exists then
        table.insert(merged.chat.tools.opts.default_tools, mcp_tool)
      else
        if os.getenv("CODECOMPANION_DEBUG") then
          print("跳过重复的默认工具:", mcp_tool)
        end
      end
    end
  end

  -- 4. 智能合并系统提示（避免重复）
  if mcp.system_prompt then
    -- 获取基础系统提示
    local base_prompt = merged.chat.tools.opts.system_prompt.prompt or ""

    -- 分析两个提示的内容，避免重复
    local mcp_prompt = mcp.system_prompt

    -- 检查基础提示中是否已包含 MCP 工具列表
    local has_mcp_tools_in_base = string.find(base_prompt, "## MCP 工具", 1, true)
    local has_crawl4ai_guide_in_base = string.find(base_prompt, "## crawl4ai 网页爬取工具使用指南", 1, true)

    -- 检查基础提示中是否已包含自主决策指南
    local has_decision_guide_in_base = string.find(base_prompt, "## 自主决策指南", 1, true)

    -- 构建最终提示
    local final_prompt = base_prompt

    -- 如果基础提示中没有 MCP 工具部分，则添加
    if not has_mcp_tools_in_base then
      -- 从 MCP 提示中提取 MCP 工具部分
      local mcp_tools_section = extract_section(mcp_prompt, "## MCP 工具", "## 工具组")
      if mcp_tools_section then
        final_prompt = final_prompt .. "\n\n" .. mcp_tools_section
      end
    end

    -- 如果基础提示中没有 crawl4ai 指南，则添加
    if not has_crawl4ai_guide_in_base then
      local crawl4ai_section = extract_section(mcp_prompt, "## crawl4ai 网页爬取工具使用指南", "## 工具组")
      if crawl4ai_section then
        final_prompt = final_prompt .. "\n\n" .. crawl4ai_section
      end
    end

    -- 如果基础提示中没有工具组部分，则添加
    local has_groups_in_base = string.find(base_prompt, "## 工具组", 1, true)
    if not has_groups_in_base then
      local groups_section = extract_section(mcp_prompt, "## 工具组", "## @{mcp_servers}")
      if groups_section then
        final_prompt = final_prompt .. "\n\n" .. groups_section
      end
    end

    -- 如果基础提示中没有 MCP 服务器智能调用部分，则添加
    local has_mcp_servers_in_base = string.find(base_prompt, "## @{mcp_servers}", 1, true)
    if not has_mcp_servers_in_base then
      local mcp_servers_section = extract_section(mcp_prompt, "## @{mcp_servers}", "## 自主决策指南")
      if mcp_servers_section then
        final_prompt = final_prompt .. "\n\n" .. mcp_servers_section
      end
    end

    -- 如果基础提示中没有自主决策指南，则添加完整的 MCP 自主决策指南
    -- 否则只添加 MCP 特定的决策指南
    if not has_decision_guide_in_base then
      local decision_section = extract_section(mcp_prompt, "## 自主决策指南", "## @{mcp_servers} 使用策略")
      if decision_section then
        final_prompt = final_prompt .. "\n\n" .. decision_section
      end
    else
      -- 基础提示中已有自主决策指南，只添加 MCP 使用策略部分
      local mcp_strategy_section = extract_section(mcp_prompt, "## @{mcp_servers} 使用策略", "## 执行流程")
      if mcp_strategy_section then
        final_prompt = final_prompt .. "\n\n" .. mcp_strategy_section
      end
    end

    -- 添加执行流程（如果缺失）
    local has_execution_flow = string.find(base_prompt, "## 执行流程", 1, true)
    if not has_execution_flow then
      local execution_section = extract_section(mcp_prompt, "## 执行流程", "$")
      if execution_section then
        final_prompt = final_prompt .. "\n\n" .. execution_section
      end
    end

    -- 优化系统提示词，避免过长
    final_prompt = context_manager.optimize_system_prompt(final_prompt)
    merged.chat.tools.opts.system_prompt.prompt = final_prompt
  end

  -- 5. 合并工具选项
  if mcp.tool_opts then
    for opt_name, opt_value in pairs(mcp.tool_opts) do
      merged.chat.tools.opts[opt_name] = opt_value
    end
  end

  -- 6. 添加 MCP Hub 自定义工具组
  local mcphub_integration = require("plugins.CodeCompanion_mcp.config.mcphub_integration")
  local mcphub_tool_groups = mcphub_integration.get_custom_tool_groups()

  if mcphub_tool_groups and mcphub_tool_groups.groups then
    for group_name, group_config in pairs(mcphub_tool_groups.groups) do
      merged.chat.tools.groups[group_name] = group_config
    end
  end

  -- 6. 添加 MCP Hub 自定义工具组
  local mcphub_integration = require("plugins.CodeCompanion_mcp.config.mcphub_integration")
  local mcphub_tool_groups = mcphub_integration.get_custom_tool_groups()

  if mcphub_tool_groups and mcphub_tool_groups.groups then
    for group_name, group_config in pairs(mcphub_tool_groups.groups) do
      merged.chat.tools.groups[group_name] = group_config
    end
  end

  -- 7. 添加上下文管理配置
  merged.chat.context_manager = context_manager.config

  -- 8. 添加上下文检查钩子
  merged.chat.before_send = function(messages)
    local needs_compress, reason = context_manager.needs_compression(messages)
    if needs_compress then
      vim.notify("上下文需要压缩: " .. reason, vim.log.levels.WARN)
      return context_manager.compress_context(messages)
    end
    return messages
  end

  return merged
end

-- 创建最终配置
M.config = deep_merge_configs(base_config, mcp_tools_config)

-- 调试：打印合并后的配置结构
local function debug_config()
  print("=== 配置合并完成 ===")
  print("默认工具数量:", #M.config.chat.tools.opts.default_tools)
  print("工具组数量:", #vim.tbl_keys(M.config.chat.tools.groups))
  print("工具数量:", #vim.tbl_keys(M.config.chat.tools))

  -- 检查关键工具是否存在
  local key_tools = {"crawl4ai", "crawl4ai_crawl", "context7", "neovim", "github", "filesystem"}
  for _, tool in ipairs(key_tools) do
    if M.config.chat.tools[tool] then
      print("✓ 工具存在:", tool)
    else
      print("✗ 工具缺失:", tool)
    end
  end
end

-- 在开发模式下启用调试
if os.getenv("CODECOMPANION_DEBUG") then
  debug_config()
end

return M
