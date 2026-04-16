-- CodeCompanion 交互策略配置 - 基础版本
-- 文件：CodeCompanion/interactions_base.lua
-- 只包含基本工具配置，不包含 MCP 工具

local M = {}

-- 基础系统提示函数
local function get_base_system_prompt()
  local str = [[## 工具组
  你可以使用工具组来一次性获得多个工具：
  - @{files}: 文件操作工具集

## 自主决策指南
  1. 分析用户请求，判断需要哪些工具
  2. 对于文件操作任务，考虑@{files}
  3. 对于需要执行命令的任务，使用@{cmd_runner}
  4. 对于需要搜索代码的任务，使用@{cmd_runner}的grep命令或@{list_code_usages}
  5. 对于需要获取网页内容的任务，使用 MCP 工具（如 crawl4ai）
  6. 复杂任务可以按需组合多个工具
  7. MCP 工具会自动发现，无需手动指定

  ## 执行流程
  - 你需要自动选择合适的工具执行
  - 需要确认的操作会询问你的许可
  - 执行结果会自动反馈给我进行分析
  - 你需要根据结果决定下一步操作
  - 修改完代码后使用#{lsp}检查代码是否正确

  请根据任务需求自主选择合适的工具，无需等待用户指定。
  若有需要用户决定或操作时等待用户操作
  尽量优先使用原来的函数名称和文件结构
  不要创建测试脚本文件，测试让用户来做
  查找优先search text不要用正则表达式，不要使用转义符]]
  return str:gsub("%s+", " ")
end

M.config = {
  chat = {
    -- 对话聊天执行任务用
    adapter = {
      name = "deepseek",
      model = "deepseek-chat",
    },

    variables = {
      ["buffer"] = {
        description = "与 LLM 共享当前缓冲区",
        callback = "interactions.chat.variables.buffer",
        opts = {
          contains_code = true,
          default_params = "diff", -- 全部|差异
          has_params = true,
          excluded = {
            buftypes = {
              "nofile",
              "quickfix",
              "prompt",
              "popup",
            },
            fts = {
              "codecompanion",
              "help",
              "terminal",
            },
          },
        },
      },
      ["lsp"] = {
        description = "共享当前缓冲区的 LSP 信息和代码",
        callback = "interactions.chat.variables.lsp",
        opts = {
          contains_code = true,
        },
      },
      ["viewport"] = {
        description = "将你在 Neovim 中看到的代码共享给 LLM",
        callback = "interactions.chat.variables.viewport",
        opts = {
          contains_code = true,
        },
      },
    },
    slash_commands = {
      ["buffer"] = {
        description = "插入打开的缓冲区",
        callback = "interactions.chat.slash_commands.builtin.buffer",
        opts = {
          contains_code = true,
          default_params = "diff", -- all|diff
        },
      },
      ["command"] = {
        description = "更改用于启动 ACP 适配器的命令",
        callback = "interactions.chat.slash_commands.builtin.command",
        ---@param opts { adapter: CodeCompanion.HTTPAdapter|CodeCompanion.ACPAdapter }
        ---@return boolean
        enabled = function(opts)
          if opts.adapter and opts.adapter.type == "acp" then
            return true
          end
          return false
        end,
        opts = {
          contains_code = false,
        },
      },
      ["compact"] = {
        description = "清除部分聊天历史，在上下文中保留摘要",
        callback = "interactions.chat.slash_commands.builtin.compact",
        enabled = function(opts)
          if opts.adapter and opts.adapter.type == "http" then
            return true
          end
          return false
        end,
        opts = {
          contains_code = false,
        },
      },
      ["fetch"] = {
        description = "插入 URL 内容",
        callback = "interactions.chat.slash_commands.builtin.fetch",
        opts = {
          adapter = "jina", -- jina（保持不变）
          cache_path = vim.fn.stdpath("data") .. "/codecompanion/urls",
        },
      },
      ["quickfix"] = {
        description = "插入 quickfix 列表条目",
        callback = "interactions.chat.slash_commands.builtin.quickfix",
        opts = {
          contains_code = true,
        },
      },
      ["file"] = {
        description = "插入文件",
        callback = "interactions.chat.slash_commands.builtin.file",
        opts = {
          contains_code = true,
          max_lines = 1000,
        },
      },
      ["help"] = {
        description = "插入帮助标签内容",
        callback = "interactions.chat.slash_commands.builtin.help",
        opts = {
          contains_code = false,
          max_lines = 128,
        },
      },
      ["image"] = {
        description = "插入图片",
        callback = "interactions.chat.slash_commands.builtin.image",
        ---@param opts { adapter: CodeCompanion.HTTPAdapter|CodeCompanion.ACPAdapter }
        ---@return boolean
        enabled = function(opts)
          if opts.adapter and opts.adapter.opts then
            return opts.adapter.opts.vision == true
          end
          return false
        end,
        opts = {
          dirs = {},
          filetypes = { "png", "jpg", "jpeg", "gif", "webp" },
        },
      },
      ["rules"] = {
        description = "将规则插入聊天缓冲区",
        callback = "interactions.chat.slash_commands.builtin.rules",
        opts = {
          contains_code = true,
        },
      },
      ["mode"] = {
        description = "更改 ACP 会话模式",
        callback = "interactions.chat.slash_commands.builtin.mode",
        ---@param opts { adapter: CodeCompanion.HTTPAdapter|CodeCompanion.ACPAdapter }
        ---@return boolean
        enabled = function(opts)
          if opts.adapter and opts.adapter.type == "acp" then
            return true
          end
          return false
        end,
        opts = {
          contains_code = false,
        },
      },
      ["now"] = {
        description = "插入当前日期和时间",
        callback = "interactions.chat.slash_commands.builtin.now",
        opts = {
          contains_code = false,
        },
      },
      ["symbols"] = {
        description = "插入选定文件的符号",
        callback = "interactions.chat.slash_commands.builtin.symbols",
        opts = {
          contains_code = true,
        },
      },
      ["terminal"] = {
        description = "插入终端输出",
        callback = "interactions.chat.slash_commands.builtin.terminal",
        opts = {
          contains_code = false,
        },
      },
      opts = {
        acp = {
          enabled = true,
          trigger = "\\",
        },
      },
    },

    tools = {
      -- 基础工具组配置
      groups = {
        ["files"] = {
          description = "与创建、读取和编辑文件相关的工具",
          prompt = "我正在给你访问${tools}的权限，以帮助你执行文件操作",
          tools = {
            "create_file",
            "delete_file",
            "file_search",
            "get_changed_files",
            "grep_search",
            "insert_edit_into_file",
            "read_file",
            "list_code_usages",
          },
          opts = {
            collapse_tools = true,
            require_approval_for_group = false,
          },
        },
      },

      -- 基础工具配置
      ["file_search"] = {
        description = "文件搜索",
        desc = "文件搜索",
        opts = {
          require_approval_before = false, -- 执行前不需要用户审批
        },
      },
      ["get_changed_files"] = {
        description = "获取已更改文件",
        desc = "获取已更改文件",
        opts = {
          require_approval_before = false, -- 执行前不需要用户审批
        },
      },
      ["read_file"] = {
        description = "读取文件内容",
        desc = "读取文件内容",
        opts = {
          require_approval_before = false, -- 执行前需用户审批
          require_cmd_approval = true, -- 命令本身需经批准
        },
      },
      ["grep_search"] = {
        description = "使用 grep 搜索代码",
        desc = "使用 grep 搜索代码",
        opts = {
          respect_gitignore = true,
          require_approval_before = false, -- 执行前需用户审批
          require_cmd_approval = true, -- 命令本身需经批准
        },
      },
      ["list_code_usages"] = {
        description = "查找代码符号的用法",
        desc = "查找代码符号的用法",
        opts = {
          require_approval_before = false, -- 执行前不需要用户审批
        },
      },
      ["fetch_webpage"] = {
        description = "获取网页内容",
        desc = "获取网页内容",
        opts = {
          require_approval_before = false, -- 执行前不需要用户审批
        },
      },
      ["insert_edit_into_file"] = {
        description = "插入或编辑文件内容",
        desc = "插入或编辑文件内容",
        opts = {
          require_approval_before = { -- 审批配置
            buffer = false, -- 编辑 Neovim 缓冲区前不需审批
            file = false, -- 编辑工作目录文件前不需审批
          },
          require_confirmation_after = true, -- 编辑后需用户确认才接受更改
          auto_accept_changes = false, -- 不自动接受更改
          file_size_limit_mb = 2, -- 文件大小限制（超过此值可能影响操作）
        },
      },
      ["create_file"] = {
        description = "创建新文件",
        desc = "创建新文件",
        opts = {
          require_approval_before = false, -- 执行前需用户审批
          require_cmd_approval = true, -- 命令本身需经批准
        },
      },
      ["delete_file"] = {
        description = "删除文件",
        desc = "删除文件",
        opts = {
          require_approval_before = true, -- 执行前需用户审批
          require_cmd_approval = false, -- 命令本身需经批准
          allowed_in_yolo_mode = false, -- 不允许在"yolo模式"下执行
        },
      },
      ["cmd_runner"] = {
        description = "执行 shell 命令", -- 工具描述
        desc = "执行 shell 命令", -- 简短描述
        opts = {
          require_approval_before = false, -- 执行前需用户审批
          require_cmd_approval = false, -- 命令本身需经批准
          allowed_in_yolo_mode = false, -- 不允许在"yolo模式"下执行
        },
      },
      ["memory"] = {
        description = "记忆存储/检索",
        desc = "记忆存储/检索",
        opts = {
          require_approval_before = false, -- 执行前需用户审批
        },
      },

      opts = {
        -- 工具执行选项配置
        auto_submit_success = true, -- 工具执行成功时自动提交结果
        auto_submit_errors = true, -- 工具执行出错时自动提交错误
        auto_tool_selection = true, -- 自动选择工具（根据用户请求）
        require_approval_before = false, -- 工具执行前不需要用户批准
        default_tools = {
          "files", -- 文件操作工具组：包含 read_file, create_file, delete_file, insert_edit_into_file
          "cmd_runner", -- 命令行执行工具：用于执行 shell 命令
          -- "memory",
          -- MCP 工具将由 MCP Hub 动态添加
        },

        folds = {
          enabled = true,
          failure_words = {
            "cancelled",
            "error",
            "failed",
            "incorrect",
            "invalid",
            "rejected",
          },
        },
        system_prompt = {
          enabled = true,
          replace_main_system_prompt = false,
          prompt = get_base_system_prompt(),
        },

        tool_replacement_message = "${tool}工具",
      },
    },

    keymaps = require("core.keymaps").codecompanion().chat(),

    opts = {
      auto_scroll = true,
      show_reasoning = true,
    },
  },

  inline = {
    adapter = {
      name = "deepseek",
      model = "deepseek-code",
    },

    keymaps = require("core.keymaps").codecompanion().inline(),

    opts = {
      diff_show_simple_prompt = true,
      diff_default_action = "accept",
      diff_prompt_text = "按 <Enter> 接受所有更改，按 <Esc> 取消",
    },
  },

  cmd = {
    adapter = {
      name = "step",
      model = "step-3.5-flash",
    },
  },

  background = {
    adapter = {
      name = "deepseek",
      model = "deepseek-chat",
    },
    enabled = true,
  },
}

return M
