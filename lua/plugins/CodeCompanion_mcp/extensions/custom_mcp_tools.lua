-- CodeCompanion 自定义 MCP 工具扩展
-- 文件: extensions/custom_mcp_tools.lua
-- 将 MCP 服务器配置为自定义工具调用

local M = {}

-- 扩展配置函数
function M.setup(opts)
  opts = opts or {}

  -- 获取 MCP 服务器配置
  local mcp_config = require("plugins.CodeCompanion_mcp.mcp.mcp")
  local servers = mcp_config.servers

  -- 创建自定义工具配置
  local custom_tools = {}

  -- 为每个 MCP 服务器创建自定义工具
  for server_name, server_config in pairs(servers) do
    if server_config.enabled then
      -- 创建服务器特定的工具
      custom_tools[server_name] = {
        enabled = true,
        description = server_config.description or "MCP 服务器工具",
        opts = {
          require_approval_before = false, -- 无需确认
          auto_trigger = true, -- 自动触发
          priority = server_config.priority or 5,
          keywords = server_config.auto_trigger_keywords or {},
        },
        -- 工具执行函数
        execute = function(params)
          -- 这里可以调用 MCP 服务器的具体功能
          local param_str = ""
          if params then
            -- 简单序列化参数
            for k, v in pairs(params) do
              param_str = param_str .. k .. "=" .. tostring(v) .. ", "
            end
            param_str = param_str:sub(1, -3) -- 移除最后的逗号和空格
          end

          local message = string.format("调用 MCP 服务器: %s\n参数: %s", 
          server_name, param_str)

          -- 在实际实现中，这里会调用 MCP 服务器的实际功能
          -- 例如：调用 context7 查询文档，调用 crawl4ai 爬取网页等

          return {
            success = true,
            message = message,
            data = {
              server = server_name,
              params = params,
              timestamp = os.time(),
            }
          }
        end
      }

      -- 为服务器创建特定的工具（如 context7__search, crawl4ai__crawl 等）
      if server_name == "context7" then
        custom_tools["context7_search"] = {
          enabled = true,
          description = "Context7 文档搜索",
          opts = {
            require_approval_before = false,
            auto_trigger = true,
            priority = 1,
            keywords = {"search", "find", "lookup", "query", "documentation"},
          },
          execute = function(params)
            return {
              success = true,
              message = "执行 Context7 文档搜索",
              data = {
                query = params.query or "",
                results = {"结果1", "结果2", "结果3"}
              }
            }
          end
        }
      elseif server_name == "crawl4ai" then
        custom_tools["crawl4ai_crawl"] = {
          enabled = true,
          description = "Crawl4AI 网页爬取",
          opts = {
            require_approval_before = false,
            auto_trigger = true,
            priority = 2,
            keywords = {"crawl", "scrape", "extract", "webpage", "website"},
          },
          execute = function(params)
            return {
              success = true,
              message = "执行 Crawl4AI 网页爬取",
              data = {
                url = params.url or "",
                content = "网页内容示例..."
              }
            }
          end
        }
      end
    end
  end

  -- 智能选择函数：根据用户输入自动选择最合适的 MCP 工具
  local function intelligent_tool_selection(user_input, available_tools)
    user_input = user_input:lower()

    -- 关键词匹配得分
    local tool_scores = {}

    -- 初始化得分
    for tool_name, _ in pairs(available_tools) do
      tool_scores[tool_name] = 0
    end

    -- 定义关键词映射
    local keyword_mappings = {
      context7 = {
        "documentation", "docs", "api", "library", "framework", "package",
        "tutorial", "guide", "example", "how to", "best practice",
        "文档", "说明书", "接口", "库", "框架", "包", "教程", "指南"
      },
      crawl4ai = {
        "crawl", "scrape", "extract", "webpage", "website", "article",
        "blog", "news", "content", "http", "https", "www", ".com",
        "爬取", "抓取", "提取", "网页", "网站", "文章", "博客", "新闻"
      },
      neovim = {
        "neovim", "vim", "editor", "buffer", "window", "tab", "plugin",
        "配置", "设置", "快捷键", "命令", "插件", "编辑器"
      },
      github = {
        "github", "repository", "repo", "git", "pull request", "issue",
        "star", "fork", "commit", "branch", "merge", "clone",
        "仓库", "代码库", "拉取请求", "问题", "星标", "分支"
      },
    }

    -- 计算关键词匹配得分
    for tool_name, keywords in pairs(keyword_mappings) do
      if available_tools[tool_name] then
        for _, keyword in ipairs(keywords) do
          if user_input:find(keyword:lower()) then
            tool_scores[tool_name] = tool_scores[tool_name] + 1
          end
        end
      end
    end

    -- 找到最高得分的工具
    local best_tool = nil
    local best_score = 0

    for tool_name, score in pairs(tool_scores) do
      if score > best_score then
        best_score = score
        best_tool = tool_name
      end
    end

    -- 如果得分高于阈值，返回推荐的工具
    local confidence = best_score / 5 -- 简单置信度计算

    return {
      recommended_tool = best_tool,
      confidence = confidence,
      scores = tool_scores,
      meets_threshold = confidence >= 0.3 -- 较低的阈值以便更频繁地触发
    }
  end

  -- 注意：MCP Hub 工具（mcphub__get_current_servers, mcphub__toggle_mcp_server）
  -- 已由 MCP Hub 扩展自动提供，无需在此重复定义

  -- 返回扩展配置
  return {
    enabled = true,
    name = "custom_mcp_tools",
    description = "自定义 MCP 工具扩展",

    -- 工具配置
    tools = custom_tools,

    -- 扩展选项
    opts = {
      -- 工具组配置
      groups = {
        web_tools = {
          description = "网页相关工具组",
          tools = {"crawl4ai_crawl", "context7_search"},
          opts = {
            collapse_tools = false,
            require_approval_for_group = false,
          }
        },
        server_management = {
          description = "MCP 服务器管理工具组",
          tools = {"mcphub__get_current_servers", "mcphub__toggle_mcp_server"},
          opts = {
            collapse_tools = false,
            require_approval_for_group = false,
          }
        }
      },

      -- 自动触发配置
      auto_detect_mcp_usage = true,
      auto_suggest_mcp_tools = true,

      -- 智能选择配置
      intelligent_selection = {
        enabled = true,
        confidence_threshold = 0.7, -- 置信度阈值
        fallback_to_manual = true, -- 回退到手动选择
        learning_enabled = true -- 启用学习模式
      },

      -- 结果显示配置
      show_result_in_chat = true,
      format_mcp_results = true,

      -- 工具调用配置
      make_tools = true, -- 创建单个工具
      show_server_tools_in_chat = true, -- 在聊天中显示工具
      add_mcp_prefix_to_tool_names = false, -- 不添加前缀
    }
  }
end

-- 工具回调处理函数
-- 这个函数会被 CodeCompanion 调用当工具被触发时
function M.tool_callback(tool_name, args, tools_system)
  -- 获取工具配置
  local config = M.setup()
  local tool = config.tools[tool_name]

  if not tool then
    return {
      status = "error",
      data = "工具未找到: " .. tool_name
    }
  end

  -- 执行工具
  if tool.execute then
    local result = tool.execute(args)

    -- 转换结果为 CodeCompanion 期望的格式
    if result.success then
      return {
        status = "success",
        data = result.message or "工具执行成功"
      }
    else
      return {
        status = "error",
        data = result.message or "工具执行失败"
      }
    end
  else
    return {
      status = "error",
      data = "工具没有执行函数: " .. tool_name
    }
  end
end

-- 导出函数
M.exports = {
  -- 获取所有 MCP 工具
  get_mcp_tools = function()
    local config = M.setup()
    return config.tools
  end,

  -- 执行 MCP 工具
  execute_mcp_tool = function(tool_name, params)
    local config = M.setup()
    local tool = config.tools[tool_name]
    if tool and tool.execute then
      return tool.execute(params)
    end
    return {
      success = false,
      message = "工具未找到: " .. tool_name
    }
  end,

  -- 检查 MCP 服务器状态
  check_mcp_status = function()
    local mcp_config = require("plugins.CodeCompanion_mcp.mcp.mcp")
    local servers = mcp_config.servers
    local status = {}

    for name, config in pairs(servers) do
      status[name] = {
        enabled = config.enabled,
        description = config.description,
        priority = config.priority
      }
    end

    return status
  end,

  -- 工具回调函数（供 CodeCompanion 调用）
  tool_callback = M.tool_callback
}

return M
