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
      filesystem = {
        "filesystem", "file", "directory", "folder", "path", "read", "write",
        "create", "delete", "move", "copy", "rename", "list",
        "文件系统", "文件", "目录", "文件夹", "路径", "读取", "写入"
      }
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

  -- 为 mcp_servers 工具组添加智能执行函数
  custom_tools["mcp_servers"] = {
    description = "MCP 服务器工具组 - 自动选择最合适的 MCP 服务器",
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_trigger = true,
      priority = 0, -- 最高优先级
      keywords = {
        "mcp", "server", "external", "service", "工具", "服务器", "外部", "服务"
      },
    },
    execute = function(params)
      local user_input = params.query or params.text or params.input or ""

      -- 智能选择最合适的工具
      local selection = intelligent_tool_selection(user_input, custom_tools)

      if selection.recommended_tool and selection.meets_threshold then
        -- 自动选择并执行推荐的工具
        local recommended_tool = custom_tools[selection.recommended_tool]

        if recommended_tool and recommended_tool.execute then
          -- 执行推荐的工具
          local result = recommended_tool.execute(params)

          -- 添加选择信息到结果
          result.selection_info = {
            recommended_tool = selection.recommended_tool,
            confidence = selection.confidence,
            scores = selection.scores,
            auto_selected = true
          }

          result.message = "🔍 智能选择: 自动使用 " .. selection.recommended_tool .. 
          " 处理您的请求 (置信度: " .. string.format("%.1f%%", selection.confidence * 100) .. ")\n\n" ..
          result.message

          return result
        end
      end

      -- 如果没有明确推荐，返回可用工具列表
      local tool_list = {}
      for name, tool in pairs(custom_tools) do
        if name ~= "mcp_servers" and tool.enabled then
          table.insert(tool_list, {
            name = name,
            description = tool.description,
            score = selection.scores and selection.scores[name] or 0
          })
        end
      end

      -- 按得分排序
      table.sort(tool_list, function(a, b)
        return a.score > b.score
      end)

      local message = "🤖 MCP 服务器工具组 - 可用工具:\n\n"

      for i, tool in ipairs(tool_list) do
        local score_indicator = tool.score > 0 and " (相关度: " .. tool.score .. ")" or ""
        message = message .. string.format("%d. @{%s}: %s%s\n", i, tool.name, tool.description, score_indicator)
      end

      message = message .. "\n💡 使用建议:\n"
      message = message .. "- 直接使用 @{工具名} 调用特定工具\n"
      message = message .. "- 或描述您的需求，我会自动选择最合适的工具"

      if selection.recommended_tool then
        message = message .. "\n\n🔍 智能推荐: " .. selection.recommended_tool .. 
        " (置信度: " .. string.format("%.1f%%", selection.confidence * 100) .. ")"
      end

      return {
        success = true,
        message = message,
        data = {
          available_tools = tool_list,
          selection = selection,
          user_input = user_input
        }
      }
    end
  }

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
        mcp_servers = {
          description = "MCP 服务器工具组 - 自动选择最合适的 MCP 服务器处理任务",
          tools = {"context7", "crawl4ai", "neovim", "github", "filesystem"},
          opts = {
            collapse_tools = true,
            require_approval_for_group = false,
            auto_select = true, -- 启用自动选择
            selection_logic = "intelligent", -- 智能选择逻辑

            -- 自动触发关键词
            auto_trigger_keywords = {
              -- 通用 MCP 关键词
              "mcp", "server", "external", "service", "api",
              "工具", "服务器", "外部", "服务", "接口",

              -- 文档相关
              "documentation", "docs", "API", "library", "framework", "package",
              "文档", "说明书", "接口文档", "库", "框架", "包",

              -- 网页相关
              "crawl", "scrape", "extract", "webpage", "website", "article",
              "爬取", "抓取", "提取", "网页", "网站", "文章",

              -- 编辑器相关
              "editor", "neovim", "vim", "buffer", "window", "tab",
              "编辑器", "缓冲区", "窗口", "标签页",

              -- GitHub 相关
              "github", "repository", "repo", "git", "pull request", "issue",
              "仓库", "代码库", "拉取请求", "问题",

              -- 文件系统相关
              "filesystem", "file", "directory", "folder", "path",
              "文件系统", "文件", "目录", "文件夹", "路径"
            },

            -- 优先级配置
            priority_rules = {
              {
                keywords = {"documentation", "docs", "API", "library", "框架", "文档"},
                tool = "context7",
                priority = 1
              },
              {
                keywords = {"crawl", "scrape", "webpage", "website", "爬取", "网页"},
                tool = "crawl4ai",
                priority = 1
              },
              {
                keywords = {"editor", "neovim", "vim", "buffer", "编辑器", "缓冲区"},
                tool = "neovim",
                priority = 1
              },
              {
                keywords = {"github", "repository", "repo", "git", "仓库", "代码库"},
                tool = "github",
                priority = 1
              },
              {
                keywords = {"filesystem", "file", "directory", "文件系统", "文件", "目录"},
                tool = "filesystem",
                priority = 1
              }
            }
          }
        },
        web_tools = {
          description = "网页相关工具组",
          tools = {"crawl4ai_crawl", "context7_search"},
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
