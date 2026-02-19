-- CodeCompanion 交互策略配置 - 基础版本
-- 文件：CodeCompanion/interactions_base.lua
-- 只包含基本工具配置，不包含 MCP 工具

local M = {}

-- 基础系统提示函数
local function get_base_system_prompt()
  local str = [[你是一个专业的 AI 编程助手，可以自主决定使用合适的工具来完成任务。

  ## 工具组
  你也可以使用工具组来一次性获得多个工具：
  - @{files}: 文件操作工具集

  ## 自主决策指南
  1. 分析用户请求，判断需要哪些工具
  2. 对于文件操作任务，考虑@{files}
  3. 对于需要执行命令的任务，使用@{cmd_runner}
  4. 对于需要搜索代码的任务，使用@{cmd_runner}的grep命令或@{list_code_usages}
  5. 对于需要获取网页内容的任务，优先考虑使用 crawl4ai 工具
  6. 对于简单的网页获取，使用 fetch_webpage
  7. 复杂任务可以按需组合多个工具

  ## 执行流程
  - 你需要自动选择合适的工具执行
  - 需要确认的操作会询问你的许可
  - 执行结果会自动反馈给我进行分析
  - 你需要根据结果决定下一步操作

  请根据任务需求自主选择合适的工具，无需等待用户指定。]]
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
          require_approval_before = false,  -- 执行前不需要用户审批
        },
      },
      ["get_changed_files"] = {
        description = "获取已更改文件",
        desc = "获取已更改文件",
        opts = {
          require_approval_before = false,  -- 执行前不需要用户审批
        },
      },
      ["read_file"] = {
        description = "读取文件内容",
        desc = "读取文件内容",
        opts = {
          require_approval_before = false,  -- 执行前需用户审批
          require_cmd_approval = true,     -- 命令本身需经批准
        },
      },
      ["grep_search"] = {
        description = "使用 grep 搜索代码",
        desc = "使用 grep 搜索代码",
        opts = {
          respect_gitignore = true,
          require_approval_before = false,  -- 执行前需用户审批
          require_cmd_approval = true,     -- 命令本身需经批准
        },
      },
      ["list_code_usages"] = {
        description = "查找代码符号的用法",
        desc = "查找代码符号的用法",
        opts = {
          require_approval_before = false,  -- 执行前不需要用户审批
        },
      },
      ["fetch_webpage"] = {
        description = "获取网页内容",
        desc = "获取网页内容",
        opts = {
          require_approval_before = false,  -- 执行前不需要用户审批
        },
      },
      ["insert_edit_into_file"] = {
        description = "插入或编辑文件内容",
        desc = "插入或编辑文件内容",
        opts = {
          require_approval_before = {       -- 审批配置
            buffer = false,                 -- 编辑 Neovim 缓冲区前不需审批
            file = false,                   -- 编辑工作目录文件前不需审批
          },
          require_confirmation_after = true, -- 编辑后需用户确认才接受更改
          auto_accept_changes = false,      -- 不自动接受更改
          file_size_limit_mb = 2,           -- 文件大小限制（超过此值可能影响操作）
        },
      },
      ["create_file"] = {
        description = "创建新文件",
        desc = "创建新文件",
        opts = {
          require_approval_before = false,   -- 执行前需用户审批
          require_cmd_approval = true,      -- 命令本身需经批准
        },
      },
      ["delete_file"] = {
        description = "删除文件",
        desc = "删除文件",
        opts = {
          require_approval_before = true,   -- 执行前需用户审批
          require_cmd_approval = false,      -- 命令本身需经批准
          allowed_in_yolo_mode = false,     -- 不允许在"yolo模式"下执行
        },
      },
      ["cmd_runner"] = {
        description = "执行 shell 命令",  -- 工具描述
        desc = "执行 shell 命令",          -- 简短描述
        opts = {
          require_approval_before = false,   -- 执行前需用户审批
          require_cmd_approval = false,      -- 命令本身需经批准
          allowed_in_yolo_mode = false,     -- 不允许在"yolo模式"下执行
        },
      },
      ["memory"] = {
        description = "记忆存储/检索",
        desc = "记忆存储/检索",
        opts = {
          require_approval_before = false,   -- 执行前需用户审批
        },
      },

      opts = {
        -- 工具执行选项配置
        auto_submit_success = true,         -- 工具执行成功时自动提交结果
        auto_submit_errors = true,          -- 工具执行出错时自动提交错误
        auto_tool_selection = true,         -- 自动选择工具（根据用户请求）
        require_approval_before = false,    -- 工具执行前不需要用户批准
        default_tools = {
          "files",           -- 文件操作工具组：包含 read_file, create_file, delete_file, insert_edit_into_file
          "cmd_runner",      -- 命令行执行工具：用于执行 shell 命令
          -- "fetch_webpage"  -- 网页获取工具：注释掉，因为现在使用 crawl4ai 进行网页爬取
          -- 注意：如需使用 crawl4ai 网页爬取工具，请确保 Docker 服务已启动
          -- 启动命令：./docker-compose-manage.sh up（在 crawl4ai 目录下）
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

    keymaps = {
      options = {
        description = "选项",
        modes = { n = "?" },
        callback = "keymaps.options",
        hide = true,
      },
      completion = {
        description = "[聊天] 补全菜单",
        modes = { i = "<C->_>" },
        index = 1,
        callback = "keymaps.completion",
      },
      send = {
        description = "[请求] 发送响应",
        modes = {
          n = { "<CR>", "<C-s>" },
          i = "<C-s>",
        },
        index = 2,
        callback = "keymaps.send",
      },
      regenerate = {
        description = "[请求] 重新生成",
        modes = { n = "gr" },
        index = 3,
        callback = "keymaps.regenerate",
      },
      close = {
        description = "[聊天] 关闭",
        modes = {
          n = "<C-d>",
          i = "<C-d>",
        },
        index = 4,
        callback = "keymaps.close",
      },
      stop = {
        description = "[请求] 停止",
        modes = { n = "<C-c>" },
        index = 5,
        callback = "keymaps.stop",
      },
      clear = {
        description = "[聊天] 清空",
        modes = { n = "gx" },
        index = 6,
        callback = "keymaps.clear",
      },
      codeblock = {
        description = "[聊天] 插入代码块",
        modes = { n = "gc" },
        index = 7,
        callback = "keymaps.codeblock",
      },
      yank_code = {
        description = "[聊天] 复制代码",
        modes = { n = "gy" },
        index = 8,
        callback = "keymaps.yank_code",
      },
      buffer_sync_all = {
        description = "[聊天] 切换缓冲区同步",
        modes = { n = "gba" },
        index = 9,
        callback = "keymaps.buffer_sync_all",
      },
      buffer_sync_diff = {
        description = "[聊天] 切换缓冲区差异同步",
        modes = { n = "gbd" },
        index = 10,
        callback = "keymaps.buffer_sync_diff",
      },
      next_chat = {
        description = "[导航] 下一个聊天",
        modes = { n = "}" },
        index = 11,
        callback = "keymaps.next_chat",
      },
      previous_chat = {
        description = "[导航] 上一个聊天",
        modes = { n = "{" },
        index = 12,
        callback = "keymaps.previous_chat",
      },
      next_header = {
        description = "[导航] 下一个标题",
        modes = { n = "]]" },
        index = 13,
        callback = "keymaps.next_header",
      },
      previous_header = {
        description = "[导航] 上一个标题",
        modes = { n = "[[" },
        index = 14,
        callback = "keymaps.previous_header",
      },
      change_adapter = {
        description = "[适配器] 更改适配器和模型",
        modes = { n = "ga" },
        index = 15,
        callback = "keymaps.change_adapter",
      },
      fold_code = {
        description = "[聊天] 折叠代码",
        modes = { n = "gf" },
        index = 15,
        callback = "keymaps.fold_code",
      },
      debug = {
        description = "[聊天] 查看调试信息",
        modes = { n = "gd" },
        index = 16,
        callback = "keymaps.debug",
      },
      system_prompt = {
        description = "[聊天] 切换系统提示",
        modes = { n = "gs" },
        index = 17,
        callback = "keymaps.toggle_system_prompt",
      },
      rules = {
        description = "[聊天] 清除规则",
        modes = { n = "gM" },
        index = 18,
        callback = "keymaps.clear_rules",
      },
      clear_approvals = {
        description = "[Tools] Clear approvals",
        modes = { n = "gtx" },
        index = 19,
        callback = "keymaps.clear_approvals",
      },
      yolo_mode = {
        description = "[Tools] Toggle YOLO mode",
        modes = { n = "gty" },
        index = 20,
        callback = "keymaps.yolo_mode",
      },
      goto_file_under_cursor = {
        description = "[Chat] Open file under cursor",
        modes = { n = "gR" },
        index = 21,
        callback = "keymaps.goto_file_under_cursor",
      },
      copilot_stats = {
        description = "[Adapter] Copilot statistics",
        modes = { n = "gS" },
        index = 22,
        callback = "keymaps.copilot_stats",
      },
      super_diff = {
        description = "[Tools] Show Super Diff",
        modes = { n = "gD" },
        index = 23,
        callback = "keymaps.super_diff",
      },
      -- Keymaps for ACP permission requests
      _acp_allow_always = {
        description = "Allow Always",
        modes = { n = "g1" },
        callback = function() end,
      },
      _acp_allow_once = {
        description = "Allow Once",
        modes = { n = "g2" },
        callback = function() end,
      },
      _acp_reject_once = {
        description = "Reject Once",
        modes = { n = "g3" },
        callback = function() end,
      },
      _acp_reject_always = {
        description = "Reject Always",
        modes = { n = "g4" },
        callback = function() end,
      },
    },

    opts = {
      auto_scroll = true,
      show_reasoning = true,
    },
  },

  inline = {
    adapter = {
      name = "deepseek",
      model = "deepseek-code"
    },

    keymaps = {
      always_accept = {
        callback = "keymaps.always_accept",
        description = "允许全部",
        index = 1,
        modes = { n = "a" },
        opts = { nowait = true },
      },
      accept_change = {
        callback = "keymaps.accept_change",
        description = "允许一次",
        index = 2,
        modes = { n = "y" },
        opts = { nowait = true, noremap = true },
      },
      reject_change = {
        callback = "keymaps.reject_change",
        description = "拒绝更改",
        index = 3,
        modes = { n = "r" },
        opts = { nowait = true, noremap = true },
      },
      {
        always_accept = {
          description = "允许全部",
          callback = "keymaps.always_accept",
          index = 1,
          modes = { n = "a" },
          opts = { nowait = true },
        },
        accept_change = {
          description = "允许一次",
          callback = "keymaps.accept_change",
          index = 2,
          modes = { n = "y" },
          opts = { nowait = true, noremap = true },
        },
        reject_change = {
          description = "拒绝更改",
          callback = "keymaps.reject_change",
          index = 3,
          modes = { n = "r" },
          opts = { nowait = true, noremap = true },
        },
        stop = {
          description = "停止",
          callback = "keymaps.stop",
          index = 4,
          modes = { n = "q" },
        },
      },
    },

    opts = {
      diff_show_simple_prompt = true,
      diff_default_action = "accept",
      diff_prompt_text = "按 <Enter> 接受所有更改，按 <Esc> 取消",
    },
  },

  cmd = {
    adapter = {
      name = "step",
      model = "step-3.5-flash"
    },
  },

  background = {
    adapter = {
      name = "deepseek",
      model = "deepseek-chat"
    },
    enabled = true,
  },
}

return M
