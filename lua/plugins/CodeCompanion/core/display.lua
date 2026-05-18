local M = {}

M.config = {
  -- 动作面板配置
  action_palette = {
    width = 95,
    height = 10,
    prompt = "提示 ", -- 交互式 LLM 调用使用的标题
    opts = {
      show_preset_actions = true,
      show_preset_prompts = true,
      show_preset_rules = true,
      title = "CodeCompanion 动作",
    },
  },

  -- 聊天显示配置
  chat = {
    icons = {
      buffer_sync_all = "󰪴 ",
      buffer_sync_diff = " ",
      chat_fold = " ",
      tool_pending = "  ",
      tool_in_progress = "  ",
      tool_failure = "  ",
      tool_success = "  ",
    },

    -- 聊天缓冲区的窗口选项
    window = {
      buflisted = true, -- 在缓冲区列表中列出聊天缓冲区？
      sticky = false, -- 切换标签页时聊天窗口跟随
      layout = "tab", -- float|vertical|horizontal|tab|buffer
      full_height = true, -- 垂直布局时使用完整高度
      position = nil, -- left|right|top|bottom (nil 将根据 vim.opt.splitright|vim.opt.splitbelow 默认设置)
      width = 0.5, ---@return number|fun(): number
      height = 0.8, ---@return number|fun(): number
      border = "single",
      relative = "editor",
      opts = {
        breakindent = true,
        linebreak = true,
        wrap = true,
      },
    },

    -- 浮动窗口选项
    floating_window = {
      width = 0.9, ---@return number|fun(): number
      height = 0.8, ---@return number|fun(): number
      border = "single",
      relative = "editor",
      opts = {},
    },

    -- 聊天缓冲区选项 --------------------------------------------------
    auto_scroll = true, -- 自动向下滚动并将光标放在末尾？
    intro_message = "欢迎使用 CodeCompanion ✨！按 ? 查看选项",
    separator = "─", -- 聊天缓冲区中不同消息之间的分隔符
    show_header_separator = false, -- 在聊天缓冲区显示标题分隔线？如果使用外部 markdown 格式化插件，请将此设置为 false
    fold_context = true, -- 在聊天缓冲区中折叠上下文？
    show_context = true, -- 在聊天缓冲区显示与 LLM 共享的上下文？
    fold_reasoning = true, -- 在聊天缓冲区中折叠推理内容？
    show_reasoning = true, -- 在聊天缓冲区显示推理内容？
    show_settings = false, -- 在聊天缓冲区顶部显示 LLM 设置？
    show_token_count = true, -- 显示每条回复的令牌数量？
    show_tools_processing = true, -- 工具执行时显示加载信息？
    start_in_insert_mode = false, -- 在插入模式下打开聊天缓冲区？

    ---显示令牌计数的函数
    ---@param tokens number
    ---@param adapter CodeCompanion.HTTPAdapter|CodeCompanion.ACPAdapter
    ---@return string
    token_count = function(tokens, adapter)
      return " (" .. tokens .. " 令牌)"
    end,
  },

  -- CLI 显示配置
  cli = {
    window = {
      opts = {
        list = false, -- 没有这个，listchars 会渲染为 "."
      },
    },
  },

  -- 差异显示配置
  diff = {
    enabled = true,
    threshold_for_chat = 6, -- 等于或低于此值时，始终在聊天缓冲区显示差异
    window = {
      opts = {},
    },
    word_highlights = {
      additions = true,
      deletions = true,
    },
  },

  -- 图标配置
  icons = {
    warning = " ",
  },

  -- 内联显示配置
  inline = {
    layout = "vertical", -- vertical|horizontal|buffer
  },

  -- 输入缓冲区显示选项
  input = {
    title = "󰅂 CodeCompanion 提示",
    window = {
      border = "single",
      width = { min = 40, max = 60 },
      height = { min = 3, max = 5 },
      relative = "cursor",
      title_pos = "left",
      row = 1,
      col = 0,
      opts = {
        number = false,
        relativenumber = false,
        signcolumn = "no",
        foldcolumn = "0",
        statuscolumn = "",
        breakindent = true,
        linebreak = true,
        wrap = true,
      },
    },
    keymaps = {
      send = {
        modes = {
          n = { "<CR>", "<C-s>" },
          i = "<C-s>",
        },
        description = "发送",
      },
      close = {
        modes = { n = { "q", "<Esc>" } },
        description = "关闭",
      },
      history_up = {
        modes = {
          i = "<Up>",
          n = "<Up>",
        },
        description = "上一个提示",
      },
      history_down = {
        modes = {
          i = "<Down>",
          n = "<Down>",
        },
        description = "下一个提示",
      },
    },
  },
}

return M
