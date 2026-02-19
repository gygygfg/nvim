local M = {}

local function safe_shell_escape(str)
  -- 安全的 shell 转义函数，专门处理 git commit 信息
  if not str then return "" end
  -- 转义单引号、双引号和反斜杠
  local escaped = str:gsub("'", "'\\''")
  escaped = escaped:gsub('"', '\\"')
  escaped = escaped:gsub('\\', '\\\\')
  -- 使用单引号包裹整个字符串
  return "'" .. escaped .. "'"
end

function M.safe_git_commit(message, options)
  -- 健壮的 git commit 函数
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
    -- 先执行 git add -A 添加所有更改（包括未跟踪的文件）
    local add_result = vim.fn.system('git add -A')
    local add_exit_code = vim.v.shell_error

    if add_exit_code ~= 0 then
      return false, "git add 失败: " .. add_result
    end

    -- 然后执行 git commit -m
    cmd = string.format('git commit -m %s', safe_shell_escape(message))
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

local function process_ai_response(response, callback)
  -- 处理 AI 响应
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

local function generate_fallback_commit_message(diff_output, callback)
  -- 备用方案：使用简单的规则生成提交信息
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

function M.generate_ai_commit_message(callback, options)
  -- AI 提交信息生成函数
  options = options or {}
  local include_unstaged = options.include_unstaged or false

  -- 获取 git diff 信息
  local diff_output

  if include_unstaged then
    -- 如果需要包含未暂存的更改，获取所有更改（暂存 + 未暂存）
    diff_output = vim.fn.system("git diff HEAD")
  else
    -- 默认只获取暂存的更改
    diff_output = vim.fn.system("git diff --cached")

    if vim.v.shell_error ~= 0 or diff_output == "" then
      -- 如果没有暂存的更改，获取未暂存的更改
      diff_output = vim.fn.system("git diff")
    end
  end

  if vim.v.shell_error ~= 0 or diff_output == "" then
    vim.notify("没有检测到 git 更改", vim.log.levels.WARN)
    callback(nil)
    return
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

vim.keymap.set("n", "<leader>gc", function()
  -- 使用自定义 git commit 功能（覆盖默认的 Gcommit）
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
      local success, commit_hash_or_error, result = M.safe_git_commit(input, { auto_stage = true })

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

      -- 由于 auto_stage=true 会添加所有更改，所以让 AI 分析所有更改（包括未暂存的）
      M.generate_ai_commit_message(function(ai_message)
        if ai_message then
          -- 显示 AI 生成的提交信息并询问是否确认
          vim.ui.input({
            prompt = "AI 生成的提交信息 (按 Enter 确认，或输入新信息): ",
            default = ai_message,
          }, function(final_input)
            if final_input and final_input ~= "" then
              -- 使用安全的 git commit 函数，启用自动暂存
              local success, commit_hash_or_error, result = M.safe_git_commit(final_input, { auto_stage = true })

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
      end, { include_unstaged = true })
    end
  end)
end, { desc = "[Git] 提交 (自定义，支持 AI 生成)" })

return M
