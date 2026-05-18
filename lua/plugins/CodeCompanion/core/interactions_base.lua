-- CodeCompanion 交互策略配置 - 基础版本
-- 文件：CodeCompanion/interactions_base.lua
-- 只包含基本工具配置，不包含 MCP 工具

local M = {}

-- 提示词模板定义
local PROMPT_TEMPLATES = {
  -- 代理组系统提示词
  AGENT_SYSTEM_PROMPT = [[<instructions>
你是一个具有跨多种编程语言和框架专家级知识的自动化编码代理。
用户会提出问题或要求你执行任务。使用可用工具收集上下文并采取行动。
如果你可以从用户的查询或上下文中推断出项目类型，请在做出更改时记住这一点。
如果用户希望你在不指定文件的情况下实现功能，请将请求分解为较小的概念，并考虑每个概念需要哪些类型的文件。
如果你不确定哪个工具相关，可以调用多个工具。重复调用工具直到任务完成 - 除非请求确实无法完成，否则不要放弃。
首先收集上下文而不是做出假设。创造性思考并探索工作空间以进行完整修复。
工具调用后不要重复自己 - 从上次停止的地方继续。
除非用户要求，否则不要在代码块中打印终端命令。
如果上下文已提供，则无需读取文件。
测试完删除创建的无用的临时测试文件
</instructions>
<toolUseInstructions>
仔细遵循 JSON 模式并包含所有必需属性。
使用工具时始终输出有效的 JSON。
使用工具来执行操作，而不是要求用户手动执行。
如果你说要采取行动，那就继续执行。
永远不要向用户说出工具的名称 - 例如，说"我将编辑文件"而不是"我将使用 insert_edit_into_file 工具"。
尽可能并行调用多个工具。
使用用户或工具输出提供的文件路径。
</toolUseInstructions>
<outputFormatting>
使用适当的 Markdown 格式。将文件名和符号用反引号包裹。
代码块示例必须使用四个反引号和语言 ID。
如果你要提供代码更改，请使用 insert_edit_into_file 工具（如果可用）而不是打印代码块。
</outputFormatting>]],

  -- 工具系统提示词
  TOOL_SYSTEM_PROMPT = [[<instructions>
你是一个高度复杂的自动化编码代理，具有跨多种不同编程语言和框架的专家级知识。
用户会提出问题或要求你执行任务，可能需要大量研究才能正确回答。有一系列工具可以让你执行操作或检索有用的上下文来回答用户的问题。
你将获得一些上下文和附件以及用户提示。如果它们与任务相关，你可以使用它们，如果不相关，可以忽略它们。
如果你可以从用户的查询或你拥有的上下文中推断出项目类型（语言、框架和库），请在做出更改时确保记住它们。
如果用户希望你实现功能并且他们没有指定要编辑的文件，请首先将用户的请求分解为较小的概念，并考虑你需要掌握每个概念的文件类型。
如果你不确定哪个工具相关，可以调用多个工具。你可以重复调用工具以执行操作或收集尽可能多的上下文，直到完全完成任务。除非你确定请求无法用你拥有的工具完成，否则不要放弃。确保你已尽一切努力收集必要上下文是你的责任。
不要对情况做出假设 - 首先收集上下文，然后执行任务或回答问题。
创造性思考并探索工作空间以进行完整修复。
工具调用后不要重复自己，从上次停止的地方继续。
除非用户要求，否则永远不要打印出带有终端命令的代码块。
如果上下文已提供，则无需读取文件。
</instructions>
<toolUseInstructions>
使用工具时，请非常仔细地遵循 json 模式，并确保包含所有必需属性。
使用工具时始终输出有效的 JSON。
如果存在执行任务的工具，请使用该工具而不是要求用户手动执行操作。
如果你说要采取行动，那么请继续使用工具来执行。
永远不要使用不存在的工具。使用适当的程序使用工具，不要写出带有工具输入的 json 代码块。
永远不要向用户说出工具的名称。例如，不要说你会使用 insert_edit_into_file 工具，而是说"我将编辑文件"。
如果你认为运行多个工具可以回答用户的问题，请尽可能并行调用它们。
调用接受文件路径的工具时，始终使用用户或工具输出提供的文件路径。
</toolUseInstructions>
<outputFormatting>
在你的答案中使用适当的 Markdown 格式。当引用用户工作空间中的文件名或符号时，用反引号包裹它。
任何代码块示例必须用四个反引号和编程语言包裹。
<example>
````languageId
// 你的代码在这里
````
</example>
语言 ID 必须是编程语言的正确标识符，例如 python、javascript、lua 等。
如果你要提供代码更改，请使用 insert_edit_into_file 工具（如果可用）直接进行更改，而不是打印出带有更改的代码块。
</outputFormatting>]],

  -- 附加上下文模板
  ADDITIONAL_CONTEXT_TEMPLATE = [[附加上下文：
所有非代码文本响应必须用 %s 语言编写。
用户的当前工作目录是 %s。
当前日期是 %s。
用户的 Neovim 版本是 %s。
neovim环境如果想要使用lua脚本用用 timeout nvim --headless -c "lua dofile('/path/to/file') 2>&1" 一定要用绝对路径不然没有输出
用户正在使用 %s 机器。如果适用，请使用系统特定命令进行响应。
]],
}

M.config = {
  chat = {
    -- 对话聊天执行任务用
    adapter = "deepseek",

    editor_context = {
      ["buffer"] = {
        description = "与 LLM 共享当前缓冲区",
        callback = "interactions.shared.editor_context.buffer",
        opts = {
          contains_code = true,
          default_params = "diff", -- 全部|差异
          has_params = true,
        },
      },
      ["lsp"] = {
        description = "共享当前缓冲区的 LSP 信息和代码",
        callback = "interactions.shared.editor_context.diagnostics",
        opts = {
          contains_code = true,
        },
      },
      ["viewport"] = {
        description = "将你在 Neovim 中看到的代码共享给 LLM",
        callback = "interactions.shared.editor_context.viewport",
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
      -- ["mode"] = {
      --   description = "更改 ACP 会话模式",
      --   callback = "interactions.chat.slash_commands.builtin.mode",
      --   ---@param opts { adapter: CodeCompanion.HTTPAdapter|CodeCompanion.ACPAdapter }
      --   ---@return boolean
      --   enabled = function(opts)
      --     if opts.adapter and opts.adapter.type == "acp" then
      --       return true
      --     else
      --       return false
      --     end
      --   end,
      --   opts = {
      --     contains_code = false,
      --   },
      -- },
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
      ["mcp"] = {
        description = "切换 MCP 服务器",
        callback = "interactions.chat.slash_commands.builtin.mcp",
        opts = {
          contains_code = false,
        },
      },
      ["resume"] = {
        description = "恢复之前的 ACP 会话",
        callback = "interactions.chat.slash_commands.builtin.resume",
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
          max_sessions = 500,
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
        ["agent"] = {
          description = "自动化编码代理 - 可以运行代码、编辑代码并代表你修改文件",
          system_prompt = function(group, ctx)
            return PROMPT_TEMPLATES.AGENT_SYSTEM_PROMPT
              .. string.format(
                PROMPT_TEMPLATES.ADDITIONAL_CONTEXT_TEMPLATE,
                ctx.language,
                ctx.cwd,
                ctx.date,
                ctx.nvim_version,
                ctx.os
              )
          end,
          tools = {
            "ask_questions",
            "create_file",
            "delete_file",
            "file_search",
            "get_changed_files",
            "get_diagnostics",
            "grep_search",
            "insert_edit_into_file",
            "read_file",
            "run_command",
          },
          opts = {
            collapse_tools = true,
            ignore_system_prompt = true,
            ignore_tool_system_prompt = true,
          },
        },
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
          },
          opts = {
            collapse_tools = true,
          },
        },
      },

      -- 基础工具配置
      ["ask_questions"] = {
        path = "interactions.chat.tools.builtin.ask_questions",
        description = "向用户提问以澄清需求或验证假设",
        visible = false,
      },
      ["create_file"] = {
        path = "interactions.chat.tools.builtin.create_file",
        description = "在当前工作目录中创建文件",
        opts = {
          require_approval_before = false,
        },
      },
      ["delete_file"] = {
        path = "interactions.chat.tools.builtin.delete_file",
        description = "删除当前工作目录中的文件",
        opts = {
          allowed_in_yolo_mode = false,
          require_approval_before = false,
        },
      },
      ["fetch_webpage"] = {
        path = "interactions.chat.tools.builtin.fetch_webpage",
        description = "从网页获取内容",
        opts = {
          adapter = "jina",
        },
      },
      ["file_search"] = {
        path = "interactions.chat.tools.builtin.file_search",
        description = "通过 glob 模式在当前工作目录中搜索文件",
        opts = {
          max_results = 500,
        },
      },
      ["get_changed_files"] = {
        path = "interactions.chat.tools.builtin.get_changed_files",
        description = "获取 git 仓库中当前文件更改的差异",
        opts = {
          max_lines = 1000,
        },
      },
      ["get_diagnostics"] = {
        path = "interactions.chat.tools.builtin.get_diagnostics",
        description = "获取给定文件的 LSP 诊断信息",
      },
      ["grep_search"] = {
        path = "interactions.chat.tools.builtin.grep_search",
        enabled = function()
          -- 目前此工具仅支持 ripgrep
          return vim.fn.executable("rg") == 1
        end,
        description = "在当前工作目录中搜索文本",
        opts = {
          max_results = 100,
          respect_gitignore = true,
          require_approval_before = false,
        },
      },
      ["insert_edit_into_file"] = {
        path = "interactions.chat.tools.builtin.insert_edit_into_file",
        description = "使用多个自动回退交互稳健地编辑现有文件",
        opts = {
          require_approval_before = { -- 执行前需要用户批准？
            buffer = false, -- 编辑 Neovim 缓冲区
            file = false, -- 编辑当前工作目录中的文件
          },
          require_confirmation_after = true, -- 编辑后需要用户确认？
          file_size_limit_mb = 2, -- 最大文件大小（MB）
        },
      },
      ["memory"] = {
        path = "interactions.chat.tools.builtin.memory",
        description = "记忆工具使 LLM 能够通过内存文件目录跨对话存储和检索信息",
        opts = {
          require_approval_before = false,
          whitelist = {}, -- 例如 { { path = "/absolute/path", as = "/alias" } }
        },
      },
      ["read_file"] = {
        path = "interactions.chat.tools.builtin.read_file",
        description = "读取当前工作目录中的文件",
        opts = {
          require_approval_before = false,
        },
      },
      ["run_command"] = {
        path = "interactions.chat.tools.builtin.run_command",
        description = "运行由 LLM 发起的 shell 命令",
        opts = {
          allowed_in_yolo_mode = false,
          require_approval_before = true,
          require_cmd_approval = false,
        },
      },
      ["web_search"] = {
        path = "interactions.chat.tools.builtin.web_search",
        description = "搜索网络信息",
        opts = {
          adapter = "tavily", -- tavily
          opts = {
            -- Tavily 选项
            search_depth = "advanced",
            topic = "general",
            chunks_per_source = 3,
            max_results = 5,
          },
        },
      },

      opts = {
        auto_submit_errors = true, -- 自动将任何错误发送给 LLM？
        auto_submit_success = true, -- 自动将任何成功输出发送给 LLM？
        notify_on_approval = true, -- 工具需要批准时通知用户？

        folds = {
          enabled = true, -- 在缓冲区中折叠工具输出？
          failure_words = { -- 指示工具输出中错误的词语。用于应用失败高亮
            "cancelled",
            "error",
            "failed",
            "incorrect",
            "invalid",
            "rejected",
          },
        },
        ---始终加载到聊天缓冲区中的工具和/或组
        ---@type string[]
        default_tools = {
          "ask_questions",
          "create_file",
          "delete_file",
          "fetch_webpage",
          "file_search",
          "get_changed_files",
          "get_diagnostics",
          "grep_search",
          "insert_edit_into_file",
          "read_file",
          "run_command",
        },

        system_prompt = {
          enabled = true, -- 启用工具系统提示？
          replace_main_system_prompt = false, -- 用工具系统提示替换主系统提示？

          ---工具系统提示
          ---@param args { ctx: CodeCompanion.SystemPrompt.Context, tools: string[]} 可用工具
          ---@return string
          prompt = function(args)
            return PROMPT_TEMPLATES.TOOL_SYSTEM_PROMPT
          end,
        },

        tool_replacement_message = "${tool}工具",
      },
    },

    keymaps = require("core.keymaps").codecompanion().chat(),

    opts = {
      ---这是与聊天中的每个请求一起发送的默认提示
      ---交互。它主要基于 GitHub Copilot Chat 的提示
      ---但有一些修改。你可以选择通过
      ---你自己的配置删除此提示，但请注意 LLM 结果可能不会那么好
      ---@param ctx CodeCompanion.SystemPrompt.Context
      ---@return string
      system_prompt = function(ctx)
        return ctx.default_system_prompt
          .. string.format(
            PROMPT_TEMPLATES.ADDITIONAL_CONTEXT_TEMPLATE,
            ctx.language,
            ctx.cwd,
            ctx.date,
            ctx.nvim_version,
            ctx.os
          )
      end,
    },
  },

  inline = {
    adapter = "deepseek",

    keymaps = require("core.keymaps").codecompanion().inline(),

    opts = {
      diff_show_simple_prompt = true,
      diff_default_action = "accept",
      diff_prompt_text = "按 <Enter> 接受所有更改，按 <Esc> 取消",
    },
  },

  cmd = {
    adapter = "step",
  },

  background = {
    adapter = "deepseek",
    enabled = true,
  },

  shared = {
    keymaps = {
      view_diff = {
        description = "查看建议的差异",
        modes = { n = "gv" },
        opts = { nowait = true },
      },
      always_accept = {
        description = "始终接受此缓冲区中的更改",
        modes = { n = "a" },
        opts = { nowait = true },
      },
      accept_change = {
        description = "接受更改",
        modes = { n = "y" },
        opts = { nowait = true, noremap = true },
      },
      reject_change = {
        description = "拒绝更改",
        modes = { n = "n" },
        opts = { nowait = true, noremap = true },
      },
      cancel = {
        description = "取消所有待处理的工具调用",
        modes = { n = "q" },
        opts = { nowait = true },
      },
      next_hunk = {
        description = "转到下一个差异块",
        modes = { n = "}" },
      },
      previous_hunk = {
        description = "转到上一个差异块",
        modes = { n = "{" },
      },
    },
  },
}

return M
