local M = {}

-- 处理 AI 响应
local function process_ai_response(response, callback)
  -- 首先检查响应是否为空
  if not response or response == "" then
    vim.notify("AI 响应为空", vim.log.levels.ERROR)
    callback(nil)
    return
  end

  -- 尝试查看是否是网络错误
  if response:match("curl:") or response:match("Connection") then
    vim.notify("网络连接错误，请检查网络", vim.log.levels.ERROR)
    callback(nil)
    return
  end

  -- 静默调试信息
  -- vim.notify("收到 AI 响应，长度: " .. #response, vim.log.levels.DEBUG)

  -- 尝试使用 vim.json.decode 解析 JSON
  local ok, parsed
  if vim.json and vim.json.decode then
    ok, parsed = pcall(vim.json.decode, response)
  else
    -- 回退到 vim.fn.json_decode
    ok, parsed = pcall(vim.fn.json_decode, response)
  end

  if ok and parsed then
    -- 成功解析 JSON
    if parsed.choices and #parsed.choices > 0 and parsed.choices[1].message then
      local content = parsed.choices[1].message.content

      -- 清理消息：移除可能的引号和空白
      content = content:gsub("^[\"']", ""):gsub("[\"']$", ""):gsub("^%s+", ""):gsub("%s+$", "")

      -- 移除 Lua 注释和代码块标记
      content = content:gsub("%-%-.*", "")  -- 移除 Lua 单行注释
      content = content:gsub("```[^`]*```", "")  -- 移除代码块
      content = content:gsub("`[^`]*`", "")  -- 移除内联代码

      -- 移除多余的空行和空白
      content = content:gsub("\n%s*\n", "\n")  -- 移除空行
      content = content:gsub("^\n+", "")  -- 移除开头的空行
      content = content:gsub("\n+$", "")  -- 移除结尾的空行
      content = content:gsub("%s+", " ")  -- 将多个空白合并为一个空格

      -- 再次清理首尾空白
      content = content:gsub("^%s+", ""):gsub("%s+$", "")

      -- 限制长度
      if #content > 50 then
        content = content:sub(1, 50)
      end

      -- 静默提示：AI 生成成功
      -- vim.notify("AI 生成的提交信息: " .. content, vim.log.levels.INFO)
      callback(content)
    else
      vim.notify("错误：API 响应格式不正确，未找到 choices 或 message 字段", vim.log.levels.ERROR)
      callback(nil)
    end
  else
    -- JSON 解析失败，尝试使用字符串匹配作为备用方案
    vim.notify("JSON 解析失败，尝试使用字符串匹配", vim.log.levels.WARN)

    -- 解析JSON响应，提取content字段中的字符串
    -- 方法：使用字符串匹配查找"content":"..."，适用于简单响应
    local content_start = string.find(response, '\"content\":\"')
    if content_start then
      content_start = content_start + 13  -- 跳过'"content":"'，定位到内容起始位置
      local content_end = string.find(response, '\"', content_start, true)  -- 查找下一个双引号作为结束
      if content_end then
        local content = string.sub(response, content_start, content_end - 1)
        -- 反转义字符串（例如，处理JSON中的换行符\n）
        content = string.gsub(content, '\\n', '\n')  -- 将\n转换为实际换行
        content = string.gsub(content, '\\\"', '\"')   -- 将\"转换为"

        -- 清理消息：移除可能的引号和空白
        content = content:gsub("^[\"']", ""):gsub("[\"']$", ""):gsub("^%s+", ""):gsub("%s+$", "")

        -- 移除 Lua 注释和代码块标记
        content = content:gsub("%-%-.*", "")  -- 移除 Lua 单行注释
        content = content:gsub("```[^`]*```", "")  -- 移除代码块
        content = content:gsub("`[^`]*`", "")  -- 移除内联代码

        -- 移除多余的空行和空白
        content = content:gsub("\n%s*\n", "\n")  -- 移除空行
        content = content:gsub("^\n+", "")  -- 移除开头的空行
        content = content:gsub("\n+$", "")  -- 移除结尾的空行
        content = content:gsub("%s+", " ")  -- 将多个空白合并为一个空格

        -- 再次清理首尾空白
        content = content:gsub("^%s+", ""):gsub("%s+$", "")

        -- 限制长度
        if #content > 50 then
          content = content:sub(1, 50)
        end

        -- 静默提示：AI 生成成功（字符串匹配）
        -- vim.notify("AI 生成的提交信息: " .. content, vim.log.levels.INFO)
        callback(content)
      else
        vim.notify("错误：无法解析content字段的结束位置。", vim.log.levels.ERROR)
        callback(nil)
      end
    else
      vim.notify("错误：响应中未找到content字段。请检查API响应结构。", vim.log.levels.ERROR)
      callback(nil)
    end
  end
end

-- 备用方案：使用简单的规则生成提交信息
local function generate_fallback_commit_message(diff_output, callback)
  -- 静默提示：使用备用方案
  -- vim.notify("使用备用规则生成提交信息", vim.log.levels.INFO)

  -- 分析 diff 内容，生成简单的提交信息
  local commit_type = "chore"
  local summary = "update files"

  -- 简单的启发式规则
  if diff_output:match("function%s+[%w_]+") or diff_output:match("def%s+[%w_]+") then
    commit_type = "feat"
    summary = "add new function"
  elseif diff_output:match("fix%f[%A]") or diff_output:match("bug%f[%A]") then
    commit_type = "fix"
    summary = "fix issue"
  elseif diff_output:match("refactor%f[%A]") then
    commit_type = "refactor"
    summary = "refactor code"
  elseif diff_output:match("test%f[%A]") then
    commit_type = "test"
    summary = "add tests"
  end

  local ai_message = commit_type .. ": " .. summary
  if #ai_message > 50 then
    ai_message = ai_message:sub(1, 50)
  end

  callback(ai_message)
end

-- AI 提交信息生成函数
local function generate_ai_commit_message(callback)
  -- 获取 git diff 信息
  local diff_output = vim.fn.system("git diff --cached")

  if vim.v.shell_error ~= 0 or diff_output == "" then
    -- 如果没有暂存的更改，获取未暂存的更改
    diff_output = vim.fn.system("git diff")

    if vim.v.shell_error ~= 0 or diff_output == "" then
      vim.notify("没有检测到 git 更改", vim.log.levels.WARN)
      callback(nil)
      return
    end
  end

  -- 限制 diff 长度，避免 token 超限
  local max_diff_length = 8000
  if #diff_output > max_diff_length then
    diff_output = diff_output:sub(1, max_diff_length) .. "\n... (truncated)"
  end

  -- 构建 AI 提示词
  local prompt = [[请根据以下 git diff 信息，生成一个简洁的提交信息。
  要求：
  1. 使用中文
  2. 不超过 20 个字符
  3. 使用 conventional commit 格式（如：feat: add new feature）
  4. 准确概括代码变更

  Git diff:
  ]] .. diff_output .. "\n\n提交信息："

  -- 静默提示：正在请求 AI
  vim.notify("正在请求 AI 生成提交信息...", vim.log.levels.INFO, { timeout = 1500 })

  -- 使用阶跃星辰 API
  -- 注意：这里使用 STEP_API_KEY 环境变量
  local api_key = os.getenv("STEP_API_KEY") or ""
  local base_url = "https://api.stepfun.com/v1"
  local model = "step-1-8k"  -- 文档中示例使用的模型

  if api_key == "" then
    vim.notify("未设置 STEP_API_KEY 环境变量，使用备用方案", vim.log.levels.WARN)
    -- 调用备用方案
    generate_fallback_commit_message(diff_output, callback)
    return
  end

  -- 构建阶跃星辰 API 格式的请求数据
  local messages = {
    {
      role = "system",
      content = "你是由阶跃星辰提供的AI聊天助手,你擅长中文,英文,以及多种其他语言的对话。在保证用户数据安全的前提下,你能对用户的问题和请求,作出快速和精准的回答。同时,你的回答和建议应该拒绝黄赌毒,暴力恐怖主义的内容"
    },
    {
      role = "user",
      content = prompt
    }
  }

  -- 使用 vim.json.encode 来构建 JSON（更可靠的方法）
  local json_data
  if vim.json and vim.json.encode then
    -- Neovim 0.10+ 支持 vim.json
    json_data = vim.json.encode({
      model = model,
      messages = messages
    })
  else
    -- 回退到字符串拼接
    local json_messages = ""
    for i, msg in ipairs(messages) do
      if i > 1 then
        json_messages = json_messages .. ","
      end
      -- 转义双引号，确保JSON有效性
      local escaped_content = string.gsub(msg.content, '"', '\\"')
      escaped_content = string.gsub(escaped_content, '\\n', '\\\\n')  -- 转义换行符
      escaped_content = string.gsub(escaped_content, '\\r', '\\\\r')  -- 转义回车符
      json_messages = json_messages .. string.format('{"role":"%s","content":"%s"}', msg.role, escaped_content)
    end
    json_data = string.format('{"model":"%s","messages":[%s]}', model, json_messages)
  end

  -- 使用临时文件传递 JSON 数据，避免 shell 转义问题
  local temp_file = os.tmpname()
  local file = io.open(temp_file, "w")
  if file then
    file:write(json_data)
    file:close()
  else
    vim.notify("错误：无法创建临时文件", vim.log.levels.ERROR)
    generate_fallback_commit_message(diff_output, callback)
    return
  end

  -- 构造curl命令：使用临时文件传递JSON数据
  local curl_cmd = string.format('curl -s -X POST "%s/chat/completions" -H "Authorization: Bearer %s" -H "Content-Type: application/json" --data-binary @%s', base_url, api_key, temp_file)

  -- 执行curl命令并读取响应
  -- 静默调试信息
  -- vim.notify("执行curl命令: " .. string.sub(curl_cmd, 1, 100) .. "...", vim.log.levels.DEBUG)
  local handle = io.popen(curl_cmd)
  local response = handle:read("*a")
  local success, err = handle:close()

  -- 清理临时文件
  pcall(os.remove, temp_file)

  -- 检查命令执行状态
  if not success then
    vim.notify("curl命令执行失败: " .. (err or "未知错误"), vim.log.levels.ERROR)
    -- 调用备用方案
    generate_fallback_commit_message(diff_output, callback)
    return
  end

  -- 检查响应是否为空或错误
  if response == "" or response == nil then
    vim.notify("错误：未收到响应。请检查API密钥、网络连接或curl安装。", vim.log.levels.ERROR)
    -- 调用备用方案
    generate_fallback_commit_message(diff_output, callback)
    return
  end

  -- 调试：显示响应前100个字符
  -- vim.notify("收到响应，长度: " .. #response .. "，前100字符: " .. string.sub(response, 1, 100), vim.log.levels.DEBUG)

  -- 处理响应
  process_ai_response(response, callback)
end

local function _set_keymap(mode, lhs, rhs, opts)
  opts = opts or { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- 安全的 shell 转义函数，专门处理 git commit 信息
local function safe_shell_escape(str)
  if not str then return "" end
  -- 转义单引号、双引号和反斜杠
  local escaped = str:gsub("'", "'\\''")
  escaped = escaped:gsub('"', '\\"')
  escaped = escaped:gsub('\\', '\\\\')
  -- 使用单引号包裹整个字符串
  return "'" .. escaped .. "'"
end

-- 健壮的 git commit 函数
local function safe_git_commit(message, options)
  options = options or {}
  local auto_stage = options.auto_stage or false

  if not message or message == "" then
    return false, "提交信息不能为空"
  end

  -- 检查是否有需要提交的更改
  local status_output = vim.fn.system("git status --porcelain")
  if vim.v.shell_error ~= 0 then
    return false, "git 状态检查失败，请确保在 git 仓库中"
  end

  if status_output == "" then
    -- 获取更详细的状态信息用于错误提示
    local detailed_status = vim.fn.system("git status")
    if vim.v.shell_error == 0 then
      -- 提取关键信息
      local lines = vim.split(detailed_status, "\n")
      local error_msg = "没有检测到需要提交的更改"
      for _, line in ipairs(lines) do
        if line:match("Changes not staged for commit") then
          error_msg = "有未暂存的更改，使用 auto_stage=true 或先执行 git add"
          break
        elseif line:match("Untracked files") then
          error_msg = "有未跟踪的文件，使用 auto_stage=true 或先执行 git add"
          break
        end
      end
      return false, error_msg
    else
      return false, "没有检测到需要提交的更改"
    end
  end

  -- 构建 git 命令
  local cmd
  if auto_stage then
    -- 使用 git commit -a -m 自动暂存所有更改
    cmd = string.format('git commit -a -m %s', safe_shell_escape(message))
  else
    -- 只提交已暂存的更改
    cmd = string.format('git commit -m %s', safe_shell_escape(message))
  end

  -- 执行命令
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code == 0 then
    -- 提取提交哈希
    local commit_hash = ""
    local lines = vim.split(result, "\n")
    for _, line in ipairs(lines) do
      if line:match("^%[%w+ [0-9a-f]+%]") then
        commit_hash = line:match("%[([0-9a-f]+)%]") or ""
        break
      end
    end
    return true, commit_hash, result
  else
    return false, result
  end
end

function M.main()
  vim.g.mapleader = " "
  -- 配置 Ctrl+S 保存
  _set_keymap('n', '<C-s>', ':w<CR>')
  _set_keymap('i', '<C-s>', '<Esc>:w<CR>a')

  -- 取消高亮
  _set_keymap("n", "<leader>h", ":nohl<CR>")
end

function M.ufo()
  -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
  _set_keymap('n', 'zR', function() require('ufo').openAllFolds() end)
  _set_keymap('n', 'zM', function() require('ufo').closeAllFolds() end)
end

function M.mason()
  -- 检测当前缓冲区是否有 ast-grep LSP 客户端（使用新 API）
  local function has_ast_grep_client()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    for _, client in ipairs(clients) do
      if client.name == 'ast_grep' then
        return true
      end
    end
    return false
  end

  local use_ast_grep = has_ast_grep_client()

  -- lsp 快捷键设置
  -- 显示悬停文档
  _set_keymap('n', 'K', vim.lsp.buf.hover)

  -- 查找引用
  _set_keymap('n', 'gr', vim.lsp.buf.references)

  -- 重命名符号
  _set_keymap('n', '<leader>rn', vim.lsp.buf.rename)

  -- 代码操作
  _set_keymap("n", "<leader>ca", vim.lsp.buf.code_action)

  -- 查看工作区文件夹
  _set_keymap('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end)

  -- 查看定义 go to definition
  _set_keymap('n', 'gd', function()
    local params = vim.lsp.util.make_position_params(nil, 'utf-16')
    vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result)
      if not result then return end
      vim.lsp.util.jump_to_location(result[1], 'utf-16')
    end)
  end, { desc = "跳转定义" })

  -- 文档显示 show hover
  _set_keymap("n", "gh", vim.lsp.buf.hover)
  _set_keymap("n", "g[", vim.diagnostic.goto_prev)
  _set_keymap("n", "g]", vim.diagnostic.goto_next)
  _set_keymap('n', 'go', vim.diagnostic.open_float)
  _set_keymap('n', '<leader>q', vim.diagnostic.setloclist)

  -- 如果 ast-grep 可用，可以添加特定功能或通知
  if use_ast_grep then
    -- 可以在这里添加 ast-grep 特有的功能
    vim.defer_fn(function()
      vim.notify("ast-grep LSP 已加载", vim.log.levels.INFO)
    end, 100)
  end
end

function M.nvim_tree()
  -- nvim-tree
  _set_keymap("n", "<leader>d", ":NvimTreeToggle<CR>")
end

function M.comment()
  -- 快捷注释
  _set_keymap('n', '<leader>l', ':CommentToggle<CR>')
  _set_keymap('x', '<leader>l', ':CommentToggle<CR>')
end

function M.terminal()
  -- terminal
  _set_keymap('n', '<leader>t', ':ToggleTerm direction=float<CR>')
  _set_keymap('i', '<C-t>', '<Esc>:w!<CR>:ToggleTerm direction=float<CR>')
end

function M.code_runner()
  -- code_runner
  _set_keymap('n', '<leader>r', ':RunCode<CR>a', { noremap = true, silent = false })
  _set_keymap('n', '<leader>rc', ':RunClose<CR>', { noremap = true, silent = false })
end

function M.translate()
  -- 翻译
  -- Ti, 支持在底部输入框输入翻译。
  _set_keymap('n', 'ti', ':<C-u>Ti<CR>')

  -- Ty, 从粘贴板中获取文字进行翻译(匿名寄存器中"")。
  _set_keymap('n', 'ty', ':<C-u>Ty<CR>')

  -- Tc, 支持翻译光标处单词。
  _set_keymap('n', 'tc', ':<C-u>Tc<CR>')

  -- Tv, 支持在visual模式下选中翻译。
  _set_keymap('v', 'tv', ':<C-u>Tv<CR>')

  -- Tr, 支持在visual模式下将文字替换成翻译。
  _set_keymap('v', 'tr', ':<C-u>Tr<CR>')
end

function M.codeCompanion()
  -- codeCompanion
  _set_keymap({ "n", "v" }, "<leader>cc", function()
    require("codecompanion").toggle() -- 开关聊天窗口
  end, { desc = "开关 CodeCompanion 聊天窗口" })

  _set_keymap("v", "<leader>cp", ":CodeCompanionActions<CR>", { desc = "选区调用 CodeCompanion 动作" }) -- 选区调用动作
end

function M.codeCompanion_chat_keymaps()
  -- CodeCompanion chat keymaps 配置
  return {
    options = {
      description = "选项",
      modes = { n = "?" },
      callback = "keymaps.options",
      hide = true,
    },
    completion = {
      description = "[聊天] 补全菜单",
      modes = { i = "<C-_>" },
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
    },
    _acp_allow_once = {
      description = "Allow Once",
      modes = { n = "g2" },
    },
    _acp_reject_once = {
      description = "Reject Once",
      modes = { n = "g3" },
    },
    _acp_reject_always = {
      description = "Reject Always",
      modes = { n = "g4" },
    },
  }
end

function M.codeCompanion_inline_keymaps()
  -- CodeCompanion inline keymaps 配置
  return {
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
  }
end

function M.treesitter_textobjects()
  -- nvim-treesitter textobjects 快捷键配置
  -- 这些快捷键已经在 nvim-treesitter.lua 中配置了 textobjects
  -- 这里只需要设置相关的快捷键

  -- 由于 textobjects 的快捷键已经在插件配置中定义（如 ]f, [f 等）
  -- 这里不需要额外设置，这个函数作为插件初始化使用

  -- 可以在这里添加一些与 treesitter textobjects 相关的额外快捷键
  -- 例如：
  -- _set_keymap('n', '<leader>ts', ':TSHighlightCapturesUnderCursor<CR>')

  -- 注意：这个函数被 nvim-treesitter.lua 的 init 选项调用
  -- 所以它应该执行实际的快捷键设置，而不是返回一个函数

  -- 添加 treesitter textobjects 相关的快捷键说明
  -- 以下快捷键由 nvim-treesitter textobjects 插件提供：
  -- [f: 跳转到上一个函数开头
  -- ]f: 跳转到下一个函数开头
  -- [m: 跳转到上一个类开头
  -- ]m: 跳转到下一个类开头

  -- 可以在这里添加额外的 textobjects 相关快捷键
  -- 例如，添加一个快捷键来显示当前光标下的 textobject 信息
  _set_keymap('n', '<leader>to', ':TSHighlightCapturesUnderCursor<CR>', { desc = "显示当前光标下的 treesitter 捕获信息" })
end

function M.fugitive()
  -- vim-fugitive 专用快捷键
  _set_keymap("n", "<leader>gs", "<cmd>Gstatus<CR>", { desc = "[Git] 状态" })
  _set_keymap("n", "<leader>gd", "<cmd>Gdiff<CR>", { desc = "[Git] 差异" })
  _set_keymap("n", "<leader>gb", "<cmd>Gblame<CR>", { desc = "[Git] 追溯" })
  -- 使用自定义 git commit 功能（覆盖默认的 Gcommit）
  _set_keymap("n", "<leader>gc", function()
    -- 首先检查是否有需要提交的更改
    local status_output = vim.fn.system("git status --porcelain")
    if vim.v.shell_error ~= 0 or status_output == "" then
      vim.notify("没有检测到需要提交的更改", vim.log.levels.WARN)
      return
    end

    -- 显示输入框获取提交信息
    vim.ui.input({
      prompt = "Commit message: ",
      default = "",
    }, function(input)
      if input and input ~= "" then
        -- 使用安全的 git commit 函数，启用自动暂存
        local success, commit_hash_or_error, result = safe_git_commit(input, { auto_stage = true })

        if success then
          if commit_hash_or_error ~= "" then
            vim.notify("✓ 提交成功: " .. commit_hash_or_error:sub(1, 8) .. " - " .. input, vim.log.levels.INFO)
          else
            vim.notify("✓ 提交成功: " .. input, vim.log.levels.INFO)
          end
        else
          vim.notify("✗ 提交失败: " .. commit_hash_or_error, vim.log.levels.ERROR)
        end
      else
        -- 用户没有输入，使用 AI 生成提交信息
        vim.notify("正在请求 AI 生成提交信息...", vim.log.levels.INFO, { timeout = 1500 })

        generate_ai_commit_message(function(ai_message)
          if ai_message then
            -- 显示 AI 生成的提交信息并询问是否确认
            vim.ui.input({
              prompt = "AI 生成的提交信息 (按 Enter 确认，或输入新信息): ",
              default = ai_message,
            }, function(final_input)
              if final_input and final_input ~= "" then
                -- 使用安全的 git commit 函数，启用自动暂存
                local success, commit_hash_or_error, result = safe_git_commit(final_input, { auto_stage = true })

                if success then
                  if commit_hash_or_error ~= "" then
                    vim.notify("✓ AI 提交成功: " .. commit_hash_or_error:sub(1, 8) .. " - " .. final_input, vim.log.levels.INFO)
                  else
                    vim.notify("✓ AI 提交成功: " .. final_input, vim.log.levels.INFO)
                  end
                else
                  vim.notify("✗ AI 提交失败: " .. commit_hash_or_error, vim.log.levels.ERROR)
                end
              else
                vim.notify("提交已取消", vim.log.levels.WARN)
              end
            end)
          else
            vim.notify("AI 生成提交信息失败，请手动输入", vim.log.levels.ERROR)
          end
        end)
      end
    end)
  end, { desc = "[Git] 提交 (自定义，支持 AI 生成)" })

  _set_keymap("n", "<leader>gp", "<cmd>Git push<CR>", { desc = "[Git] 推送" })
  _set_keymap("n", "<leader>gl", "<cmd>Git pull<CR>", { desc = "[Git] 拉取" })
  _set_keymap("n", "<leader>gw", "<cmd>Gwrite<CR>", { desc = "[Git] 暂存文件" })
  _set_keymap("n", "<leader>gr", "<cmd>Gread<CR>", { desc = "[Git] 检出文件" })
  -- 在 Gstatus 窗口中的快捷键（安装后自动生效）
  -- s: 暂存/取消暂存文件
  -- u: 取消暂存
  -- cc: 提交
  -- ca: 修改提交
  -- ce: 修改提交（不编辑信息）
  -- 在 Neovim 配置中添加
  vim.api.nvim_create_user_command("Gitignore", function()
    -- 生成.gitignore文件
    local filetypes = vim.fn.input("输入技术栈 (如 node,python): ")
    if filetypes ~= "" then
      local cmd = string.format("curl -sL https://www.toptal.com/developers/gitignore/api/%s > .gitignore", filetypes)
      vim.fn.system(cmd)
      vim.cmd("edit .gitignore")
      print("Gitignore 文件已生成")
    end
  end, {})
  vim.api.nvim_create_autocmd("BufReadPost", {
    -- 当检测到合并冲突时自动打开 diff 视图
    pattern = "*",
    callback = function()
      if vim.fn.search("^<<<<<<<", "nw") > 0 then
        vim.notify("检测到合并冲突，正在打开 Gdiff...", vim.log.levels.INFO)
        vim.defer_fn(function()
          vim.cmd("Gdiff")
        end, 100)
      end
    end
  })
  _set_keymap("n", "<leader>gb", function()
    -- 快捷键：快速 blame 并定位问题
    vim.cmd("Gblame")
    -- 自动调整窗口布局
    vim.cmd("wincmd L")
    vim.cmd("vertical resize 40")
  end, { desc = "Git Blame (详细模式)" })

  -- 添加 telescope git_commits 快捷键
  _set_keymap("n", "<leader>gh", function()
    require("telescope.builtin").git_commits()
  end, { desc = "Git 提交历史 (telescope)" })

  -- 测试 git commit 功能的快捷键
  _set_keymap("n", "<leader>gt", function()
    -- 测试安全的 git commit 函数
    local test_messages = {
      "测试中文提交信息",
      "feat: 添加新功能",
      "fix: 修复bug",
      "chore: 更新依赖",
      "包含'单引号'的测试",
      "包含\"双引号\"的测试",
      "包含特殊字符!@#$%^&*()的测试",
      "移除测试文件和备份文件"  -- 这是原始错误信息
    }

    vim.ui.select(test_messages, {
      prompt = "选择测试提交信息:",
    }, function(choice)
      if choice then
        vim.notify("测试提交信息: " .. choice, vim.log.levels.INFO)
        local success, commit_hash_or_error, result = safe_git_commit(choice, { auto_stage = true })
        if success then
          if commit_hash_or_error ~= "" then
            vim.notify("✓ 测试成功: " .. commit_hash_or_error:sub(1, 8), vim.log.levels.INFO)
          else
            vim.notify("✓ 测试成功", vim.log.levels.INFO)
          end
        else
          vim.notify("✗ 测试失败: " .. commit_hash_or_error, vim.log.levels.ERROR)
        end
      end
    end)
  end, { desc = "测试 git commit 功能" })
end

return M
