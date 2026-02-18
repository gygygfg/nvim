-- 上下文管理器配置
-- 用于管理聊天上下文长度，避免超过模型限制

local M = {}

-- 默认上下文配置
M.config = {
  -- 最大 token 限制（根据模型调整）
  max_tokens = 120000, -- 留一些余量，避免刚好超过限制
  
  -- 自动压缩设置
  auto_compact = {
    enabled = true,
    threshold = 0.8, -- 当上下文达到最大限制的80%时自动压缩
    keep_messages = 10, -- 保留最近的消息数量
  },
  
  -- 系统提示词优化
  system_prompt = {
    max_length = 2000, -- 系统提示词最大长度（字符）
    compress = true, -- 是否压缩系统提示词
  },
  
  -- 消息管理
  message_management = {
    max_messages = 50, -- 最大消息数量
    trim_oldest = true, -- 是否自动修剪最旧的消息
    preserve_system = true, -- 保留系统消息
    preserve_tool_calls = true, -- 保留工具调用消息
  },
  
  -- 代码内容管理
  code_content = {
    max_lines_per_file = 500, -- 每个文件最大行数
    compress_large_files = true, -- 压缩大文件
    show_summary_only = false, -- 是否只显示摘要
  }
}

-- 上下文压缩函数
function M.compress_context(messages, config)
  config = config or M.config
  
  if #messages <= config.message_management.max_messages then
    return messages
  end
  
  local compressed = {}
  
  -- 保留系统消息
  for _, msg in ipairs(messages) do
    if msg.role == "system" and config.message_management.preserve_system then
      table.insert(compressed, msg)
    end
  end
  
  -- 保留工具调用消息
  for _, msg in ipairs(messages) do
    if msg.tool_calls and config.message_management.preserve_tool_calls then
      table.insert(compressed, msg)
    end
  end
  
  -- 保留最新的消息
  local start_index = math.max(1, #messages - config.auto_compact.keep_messages + 1)
  for i = start_index, #messages do
    local msg = messages[i]
    -- 跳过已添加的消息
    local skip = false
    for _, added_msg in ipairs(compressed) do
      if added_msg == msg then
        skip = true
        break
      end
    end
    if not skip then
      table.insert(compressed, msg)
    end
  end
  
  -- 添加压缩摘要
  if #compressed < #messages then
    local removed_count = #messages - #compressed
    table.insert(compressed, 1, {
      role = "system",
      content = string.format("[上下文已自动压缩，移除了 %d 条较早的消息以保持在 token 限制内]", removed_count)
    })
  end
  
  return compressed
end

-- 估算 token 数量（简单估算）
function M.estimate_tokens(text)
  if not text then return 0 end
  -- 简单估算：英文字符约0.25个token，中文字符约1.5个token
  local english_chars = #text:gsub("[^\32-\126]", "")
  local chinese_chars = #text - english_chars
  return math.floor(english_chars * 0.25 + chinese_chars * 1.5)
end

-- 检查是否需要压缩
function M.needs_compression(messages, config)
  config = config or M.config
  
  -- 检查消息数量
  if #messages > config.message_management.max_messages then
    return true, "消息数量超过限制"
  end
  
  -- 估算总 token 数
  local total_tokens = 0
  for _, msg in ipairs(messages) do
    if msg.content then
      total_tokens = total_tokens + M.estimate_tokens(msg.content)
    end
  end
  
  if total_tokens > config.max_tokens * config.auto_compact.threshold then
    return true, string.format("token 数量接近限制 (%.0f/%.0f)", total_tokens, config.max_tokens)
  end
  
  return false, nil
end

-- 优化系统提示词
function M.optimize_system_prompt(prompt, config)
  config = config or M.config
  
  if not prompt or #prompt <= config.system_prompt.max_length then
    return prompt
  end
  
  if config.system_prompt.compress then
    -- 简单压缩：移除多余的空行和注释
    local compressed = prompt:gsub("\n%s*\n+", "\n\n") -- 压缩多个空行
    compressed = compressed:gsub("%-%-%s*[^\n]*\n", "") -- 移除 Lua 注释
    compressed = compressed:gsub("##[^\n]*\n", "") -- 移除部分标题
    
    if #compressed <= config.system_prompt.max_length then
      return compressed
    end
    
    -- 如果还是太长，截断并添加说明
    return compressed:sub(1, config.system_prompt.max_length - 100) .. 
           "\n\n[系统提示词已压缩以避免超过上下文长度限制]"
  end
  
  -- 不压缩，直接截断
  return prompt:sub(1, config.system_prompt.max_length) .. 
         "\n\n[系统提示词已截断]"
end

return M