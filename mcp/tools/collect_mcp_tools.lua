-- MCP 工具收集和格式化脚本
-- 自动收集所有 MCP 服务器的工具信息并格式化为 CodeCompanion 工具集格式

local M = {}

-- MCP 服务器配置
local MCP_SERVERS = {
  context7 = {
    name = "Context7",
    description = "获取最新的代码库文档和示例",
    tools = {
      {
        name = "resolve_library_id",
        description = "解析库标识符，获取库的详细信息",
        input_schema = {
          type = "object",
          properties = {
            query = {
              type = "string",
              description = "库名称或标识符，如 'react', 'express', 'django'"
            }
          },
          required = {"query"}
        }
      },
      {
        name = "get_library_docs",
        description = "获取指定库的文档和代码示例",
        input_schema = {
          type = "object",
          properties = {
            library_id = {
              type = "string",
              description = "库ID，可通过 resolve_library_id 获取"
            },
            version = {
              type = "string",
              description = "库版本，如 'latest', '18.0.0', '4.18.0'"
            },
            query = {
              type = "string",
              description = "查询内容，如 'hooks', 'middleware', 'models'"
            }
          },
          required = {"library_id"}
        }
      },
      {
        name = "search_documentation",
        description = "搜索文档和代码示例",
        input_schema = {
          type = "object",
          properties = {
            query = {
              type = "string",
              description = "搜索查询，如 'React hooks', 'Python async', 'Docker compose'"
            }
          },
          required = {"query"}
        }
      }
    }
  },
  crawl4ai = {
    name = "Crawl4AI",
    description = "网页爬取和内容提取",
    tools = {
      {
        name = "crawl_webpage",
        description = "爬取网页内容并提取结构化信息",
        input_schema = {
          type = "object",
          properties = {
            url = {
              type = "string",
              description = "网页URL，如 'https://example.com', 'https://news.ycombinator.com'"
            },
            mode = {
              type = "string",
              description = "爬取模式：'markdown', 'html', 'text', 'screenshot'",
              default = "markdown"
            },
            extract_rules = {
              type = "object",
              description = "提取规则，用于结构化提取内容"
            }
          },
          required = {"url"}
        }
      },
      {
        name = "extract_content",
        description = "从网页内容中提取特定信息",
        input_schema = {
          type = "object",
          properties = {
            content = {
              type = "string",
              description = "网页内容或HTML"
            },
            selector = {
              type = "string",
              description = "CSS选择器或XPath，如 '.article', '//h1', '#main'"
            },
            extract_type = {
              type = "string",
              description = "提取类型：'text', 'html', 'links', 'images'",
              default = "text"
            }
          },
          required = {"content", "selector"}
        }
      },
      {
        name = "batch_crawl",
        description = "批量爬取多个网页",
        input_schema = {
          type = "object",
          properties = {
            urls = {
              type = "array",
              description = "URL列表",
              items = { type = "string" }
            },
            concurrency = {
              type = "number",
              description = "并发数",
              default = 3
            }
          },
          required = {"urls"}
        }
      }
    }
  },
  github = {
    name = "GitHub",
    description = "GitHub 仓库和项目管理",
    tools = {
      {
        name = "list_repositories",
        description = "列出用户的仓库",
        input_schema = {
          type = "object",
          properties = {
            username = {
              type = "string",
              description = "GitHub用户名"
            },
            type = {
              type = "string",
              description = "仓库类型：'all', 'owner', 'member'",
              default = "all"
            }
          }
        }
      },
      {
        name = "get_repository",
        description = "获取仓库详细信息",
        input_schema = {
          type = "object",
          properties = {
            owner = {
              type = "string",
              description = "仓库所有者"
            },
            repo = {
              type = "string",
              description = "仓库名称"
            }
          },
          required = {"owner", "repo"}
        }
      },
      {
        name = "create_issue",
        description = "创建 GitHub Issue",
        input_schema = {
          type = "object",
          properties = {
            owner = {
              type = "string",
              description = "仓库所有者"
            },
            repo = {
              type = "string",
              description = "仓库名称"
            },
            title = {
              type = "string",
              description = "Issue标题"
            },
            body = {
              type = "string",
              description = "Issue内容"
            }
          },
          required = {"owner", "repo", "title"}
        }
      }
    }
  },
  filesystem = {
    name = "Filesystem",
    description = "文件系统操作",
    tools = {
      {
        name = "list_files",
        description = "列出目录中的文件",
        input_schema = {
          type = "object",
          properties = {
            path = {
              type = "string",
              description = "目录路径",
              default = "."
            },
            recursive = {
              type = "boolean",
              description = "是否递归列出",
              default = false
            }
          }
        }
      },
      {
        name = "read_file",
        description = "读取文件内容",
        input_schema = {
          type = "object",
          properties = {
            path = {
              type = "string",
              description = "文件路径"
            }
          },
          required = {"path"}
        }
      },
      {
        name = "write_file",
        description = "写入文件内容",
        input_schema = {
          type = "object",
          properties = {
            path = {
              type = "string",
              description = "文件路径"
            },
            content = {
              type = "string",
              description = "文件内容"
            }
          },
          required = {"path", "content"}
        }
      }
    }
  },
  neovim = {
    name = "Neovim",
    description = "Neovim 编辑器和缓冲区操作",
    tools = {
      {
        name = "get_buffer",
        description = "获取当前缓冲区内容",
        input_schema = {
          type = "object",
          properties = {
            bufnr = {
              type = "number",
              description = "缓冲区编号，0表示当前缓冲区"
            }
          }
        }
      },
      {
        name = "list_buffers",
        description = "列出所有缓冲区",
        input_schema = {
          type = "object",
          properties = {}
        }
      },
      {
        name = "execute_command",
        description = "执行 Neovim 命令",
        input_schema = {
          type = "object",
          properties = {
            command = {
              type = "string",
              description = "Neovim 命令"
            }
          },
          required = {"command"}
        }
      }
    }
  }
}

-- 生成工具集格式
function M.generate_toolset()
  local toolset = {}
  
  for server_name, server_info in pairs(MCP_SERVERS) do
    -- 添加服务器级别的工具
    table.insert(toolset, {
      name = server_name,
      description = server_info.description,
      enabled = true,
      opts = {
        require_approval_before = false,
        auto_submit_success = true,
        auto_submit_errors = true,
      }
    })
    
    -- 添加服务器特定的工具
    for _, tool in ipairs(server_info.tools) do
      local tool_name = server_name .. "__" .. tool.name
      table.insert(toolset, {
        name = tool_name,
        description = tool.description,
        enabled = true,
        opts = {
          require_approval_before = false,
          auto_submit_success = true,
          auto_submit_errors = true,
        }
      })
    end
  end
  
  -- 添加 MCP 总工具
  table.insert(toolset, {
    name = "mcp",
    description = "访问所有可用的 MCP 服务器",
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    }
  })
  
  return toolset
end

-- 生成工具文档
function M.generate_documentation()
  local docs = {}
  
  table.insert(docs, "# MCP 工具文档")
  table.insert(docs, "")
  table.insert(docs, "## 概述")
  table.insert(docs, "本文档包含所有已配置的 MCP 服务器及其工具的详细信息。")
  table.insert(docs, "")
  
  for server_name, server_info in pairs(MCP_SERVERS) do
    table.insert(docs, "## " .. server_info.name .. " (`" .. server_name .. "`)")
    table.insert(docs, "")
    table.insert(docs, server_info.description)
    table.insert(docs, "")
    table.insert(docs, "### 工具列表")
    table.insert(docs, "")
    
    -- 服务器级别工具
    table.insert(docs, "#### 服务器工具 (`@" .. server_name .. "`)")
    table.insert(docs, "- **描述**: 访问 " .. server_info.name .. " 的所有功能")
    table.insert(docs, "- **使用方式**: `@{" .. server_name .. "} [查询内容]`")
    table.insert(docs, "- **示例**: `@{" .. server_name .. "} " .. (server_name == "context7" and "Get React documentation" or server_name == "crawl4ai" and "Crawl https://example.com" or "List files") .. "`")
    table.insert(docs, "")
    
    -- 特定工具
    table.insert(docs, "#### 特定工具")
    table.insert(docs, "")
    for _, tool in ipairs(server_info.tools) do
      local tool_name = server_name .. "__" .. tool.name
      table.insert(docs, "##### `" .. tool_name .. "`")
      table.insert(docs, "- **描述**: " .. tool.description)
      table.insert(docs, "- **输入参数**:")
      
      if tool.input_schema and tool.input_schema.properties then
        for param_name, param_info in pairs(tool.input_schema.properties) do
          table.insert(docs, "  - `" .. param_name .. "`: " .. param_info.description)
          if param_info.default then
            table.insert(docs, "    - 默认值: `" .. tostring(param_info.default) .. "`")
          end
          if param_info.type then
            table.insert(docs, "    - 类型: `" .. param_info.type .. "`")
          end
        end
      end
      
      table.insert(docs, "- **使用方式**: `@{" .. tool_name .. "} [参数]`")
      table.insert(docs, "")
    end
    
    table.insert(docs, "---")
    table.insert(docs, "")
  end
  
  -- 添加使用示例
  table.insert(docs, "## 使用示例")
  table.insert(docs, "")
  table.insert(docs, "### Context7 示例")
  table.insert(docs, "```")
  table.insert(docs, "@{context7} Get React hooks documentation")
  table.insert(docs, "@{context7__get_library_docs} {library_id: 'react', version: 'latest', query: 'hooks'}")
  table.insert(docs, "```")
  table.insert(docs, "")
  table.insert(docs, "### Crawl4AI 示例")
  table.insert(docs, "```")
  table.insert(docs, "@{crawl4ai} Crawl https://news.ycombinator.com")
  table.insert(docs, "@{crawl4ai__crawl_webpage} {url: 'https://example.com', mode: 'markdown'}")
  table.insert(docs, "```")
  table.insert(docs, "")
  table.insert(docs, "### 自动调用")
  table.insert(docs, "在查询中添加以下关键词自动调用相应服务：")
  table.insert(docs, "- `use context7`: 强制使用 Context7")
  table.insert(docs, "- `use crawl4ai`: 强制使用 Crawl4AI")
  table.insert(docs, "- `use mcp`: 使用所有 MCP 服务")
  table.insert(docs, "")
  
  return table.concat(docs, "\n")
end

-- 保存工具集到文件
function M.save_toolset()
  local toolset = M.generate_toolset()
  local docs = M.generate_documentation()
  
  -- 保存工具集配置
  local toolset_file = vim.fn.expand("~/.config/nvim/mcp/tools/toolset.lua")
  local f = io.open(toolset_file, "w")
  if f then
    f:write("-- 自动生成的 MCP 工具集配置\n")
    f:write("-- 生成时间: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
    f:write("return {\n")
    
    for _, tool in ipairs(toolset) do
      f:write("  [\"" .. tool.name .. "\"] = {\n")
      f:write("    enabled = " .. tostring(tool.enabled) .. ",\n")
      f:write("    opts = {\n")
      f:write("      require_approval_before = " .. tostring(tool.opts.require_approval_before) .. ",\n")
      f:write("      auto_submit_success = " .. tostring(tool.opts.auto_submit_success) .. ",\n")
      f:write("      auto_submit_errors = " .. tostring(tool.opts.auto_submit_errors) .. ",\n")
      f:write("    },\n")
      f:write("    desc = \"" .. (tool.description or "") .. "\",\n")
      f:write("  },\n")
    end
    
    f:write("}\n")
    f:close()
    print("工具集配置已保存到: " .. toolset_file)
  else
    print("无法保存工具集配置到: " .. toolset_file)
  end
  
  -- 保存文档
  local docs_file = vim.fn.expand("~/.config/nvim/mcp/tools/documentation.md")
  local f2 = io.open(docs_file, "w")
  if f2 then
    f2:write(docs)
    f2:close()
    print("工具文档已保存到: " .. docs_file)
  else
    print("无法保存工具文档到: " .. docs_file)
  end
  
  return toolset_file, docs_file
end

-- 集成到 CodeCompanion 配置
function M.integrate_with_codecompanion()
  local codecompanion_config = vim.fn.expand("~/.config/nvim/lua/plugins/codeCompanion.lua")
  
  -- 读取现有配置
  local f = io.open(codecompanion_config, "r")
  if not f then
    print("无法读取 CodeCompanion 配置文件: " .. codecompanion_config)
    return false
  end
  
  local content = f:read("*a")
  f:close()
  
  -- 查找 tools 配置部分
  local tools_section_start = content:find('tools = {')
  if not tools_section_start then
    print("未找到 tools 配置部分")
    return false
  end
  
  -- 查找 tools 配置结束位置
  local tools_section_end = content:find('},', tools_section_start)
  if not tools_section_end then
    print("未找到 tools 配置结束位置")
    return false
  end
  
  -- 生成新的 tools 配置
  local new_tools_config = 'tools = {\n      opts = {\n        auto_submit_success = true, -- 成功时自动提交工具输出\n        auto_submit_errors = true,  -- 错误时自动提交\n        auto_tool_selection = true, -- 让AI自主选择工具\n        require_approval_before = false,\n        default_tools = {           -- 默认启用的工具\n          "read_file",\n          "grep_search",\n          "list_code_usages",\n          "insert_edit_into_file",\n          "cmd_runner",\n        },\n      },\n\n'
  
  -- 添加 MCP 工具
  local toolset = M.generate_toolset()
  for _, tool in ipairs(toolset) do
    new_tools_config = new_tools_config .. '      ["' .. tool.name .. '"] = {\n'
    new_tools_config = new_tools_config .. '        enabled = ' .. tostring(tool.enabled) .. ',\n'
    new_tools_config = new_tools_config .. '        opts = {\n'
    new_tools_config = new_tools_config .. '          require_approval_before = ' .. tostring(tool.opts.require_approval_before) .. ',\n'
    new_tools_config = new_tools_config .. '          auto_submit_success = ' .. tostring(tool.opts.auto_submit_success) .. ',\n'
    new_tools_config = new_tools_config .. '          auto_submit_errors = ' .. tostring(tool.opts.auto_submit_errors) .. ',\n'
    new_tools_config = new_tools_config .. '        },\n'
    new_tools_config = new_tools_config .. '        desc = "' .. tool.description .. '",\n'
    new_tools_config = new_tools_config .. '      },\n'
  end
  
  -- 添加工具组
  new_tools_config = new_tools_config .. '\n      -- 工具组配置（继承各工具权限）\n      groups = {\n        ["coding_suite"] = {\n          description = "编程工具套件",\n          system_prompt = "我可以使用${tools}工具来帮助你完成编程任务",\n          tools = {\n            "read_file",             -- 无需确认\n            "create_file",           -- 需要确认\n            "grep_search",           -- 无需确认\n            "list_code_usages",      -- 无需确认\n            "insert_edit_into_file", -- 需要确认\n          },\n          opts = {\n            collapse_tools = true,\n            require_approval_for_group = false,\n          },\n        },\n        ["mcp_suite"] = {\n          description = "MCP 工具套件",\n          system_prompt = "我可以使用 MCP 工具来获取外部信息和执行系统操作",\n          tools = {\n            "context7",\n            "crawl4ai",\n            "github",\n            "filesystem",\n            "neovim",\n          },\n          opts = {\n            collapse_tools = true,\n            require_approval_for_group = false,\n          },\n        },\n      },\n    },\n'
  
  -- 替换 tools 配置部分
  local before_tools = content:sub(1, tools_section_start - 1)
  local after_tools = content:sub(tools_section_end + 2) -- +2 跳过 "},\n"
  
  local new_content = before_tools .. new_tools_config .. after_tools
  
  -- 保存更新后的配置
  local f = io.open(codecompanion_config, "w")
  if f then
    f:write(new_content)
    f:close()
    print("CodeCompanion 配置已更新: " .. codecompanion_config)
    return true
  else
    print("无法保存更新后的配置: " .. codecompanion_config)
    return false
  end
end

-- 主函数
function M.setup()
  print("开始收集 MCP 工具信息...")
  
  -- 保存工具集和文档
  local toolset_file, docs_file = M.save_toolset()
  
  -- 集成到 CodeCompanion
  local success = M.integrate_with_codecompanion()
  
  if success then
    print("✅ MCP 工具集成完成！")
    print("📁 工具集配置: " .. toolset_file)
    print("📄 工具文档: " .. docs_file)
    print("🚀 请重启 Neovim 或重新加载 CodeCompanion 配置以生效")
  else
    print("❌ MCP 工具集成失败")
  end
end

return M
