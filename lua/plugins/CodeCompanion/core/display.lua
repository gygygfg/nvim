-- CodeCompanion 显示配置
-- 文件: CodeCompanion/display.lua

local M = {}

M.config = {
  display = {
    diff = {
      enabled = true,

      -- At or below this diff size, always display the diff in the chat buffer
      threshold_for_chat = 6,

      word_highlights = {
        additions = true,
        deletions = true,
      },
    },
  },
  chat = {
    -- 窗口配置：设置为悬浮窗布局
    window = {
      -- layout = "float",    -- 悬浮窗布局
      -- width = 1.0,         -- 占编辑器宽度的100%
      -- height = 0.8,        -- 占编辑器高度的80%
      -- relative = "editor", -- 相对于编辑器窗口
      -- border = "rounded",  -- 圆角边框，更美观
      buflisted = true,   -- 設置為 true，讓聊天緩衝區出現在緩衝區列表中
      sticky = false,     -- 可選：控制切換標籤頁時聊天窗口是否保持打開
      layout = "buffer",  -- float|vertical|horizontal|buffer 聊天窗口的佈局方式

      full_height = true, -- 垂直布局时使用完整高度
      position = nil,     -- left|right|top|bottom (nil 将根据 vim.opt.splitright|vim.opt.splitbelow 默认设置)

      width = 1.0, ---@return number|fun(): number
      height = 1.0, ---@return number|fun(): number
      border = "single",
      relative = "editor",



      -- 注意：根据源码，当 layout = "float" 时，
      -- 如果不指定 row 和 col，窗口会自动居中
      -- 所以我们移除 row 和 col 配置，让系统自动计算居中位置

      -- 窗口选项
      opts = {
        breakindent = true,
        linebreak = true,
        wrap = true,
      },
    },

    -- 修改 diff 配置以支持简化操作
    diff = {
      enabled = true,
      provider = "inline",
      provider_opts = {
        inline = {
          layout = "float",
          opts = {
            context_lines = 3,
            -- 移除复杂的按键提示，只显示简化提示
            show_keymap_hints = false, -- 改为 false
            -- 自定义简化提示
            custom_prompt = "按回车确认所有更改",
          },
        },
      },
    },

    ui = {
      show_roles = true,
      show_timestamps = false,
      completion = {
        enabled = true,
        source = "cmp",
      },
    },
    fold_context = true, -- 上下文可以折叠
    fold_reasoning = true, -- 折叠推理过程
    show_reasoning = false, -- 显示推理过程
    separator = "─", -- 聊天缓冲区中不同消息之间的分隔符
    show_context = true, -- 在聊天缓冲区显示上下文（来自斜杠命令和变量）？
    show_header_separator = false, -- 在聊天缓冲区显示标题分隔线？如果使用外部 Markdown 格式化插件，请将此设置为 false
    show_settings = false, -- 在聊天缓冲区顶部显示 LLM 设置？
    show_token_count = true, -- 显示每条回复的令牌数量？
    show_tools_processing = false, -- 工具执行时显示加载信息？
    start_in_insert_mode = true, -- 打开聊天缓冲区时进入插入模式？
  },

  -- 工作流显示配置
  workflows = {
    show_progress = true,
    confirm_before_execution = true,
    show_tool_calls = true,
  },
}

return M
