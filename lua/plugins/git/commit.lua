local M = {}

-- ============================================================
-- 自建 HTTP + JSON：不依赖 NeoAI 内部模块
-- 协议：OpenAI 兼容（POST {base_url}/chat/completions，Bearer 鉴权）
-- ============================================================

--- 默认配置。可被环境变量（COMMIT_AI_*）或 M.configure()/M.setup({...}) 覆盖。
--- 目标端点需为 OpenAI 兼容协议，例如 deepseek / openai / glm / moonshot 等。
local config = {
  base_url = os.getenv("COMMIT_AI_BASE_URL") or "https://api.deepseek.com",
  api_key = os.getenv("COMMIT_AI_API_KEY") or os.getenv("DEEPSEEK_API_KEY") or "",
  model = os.getenv("COMMIT_AI_MODEL") or "deepseek-chat",
  temperature = 0.3,
  max_tokens = 512,
  timeout_ms = 60000,
  max_retries = 2,
}

--- 覆盖配置（仅合并传入的字段）
--- @param overrides table|nil { base_url?, api_key?, model?, temperature?, max_tokens?, timeout_ms?, max_retries? }
function M.configure(overrides)
  for k, v in pairs(overrides or {}) do
    config[k] = v
  end
end

-- ========== 极简 JSON 编解码 ==========
-- 仅覆盖本项目所需：对象/数组/字符串/数字/布尔/null，字符串转义与 \u 解码。

local json = {}

--- 解码一个 UTF-8 字符。合法返回 (codepoint, 下一字节位置)，非法返回 nil。
local function utf8_decode_char(s, i)
  local b = s:byte(i)
  if not b then
    return nil
  end
  local function is_cont(k)
    local c = s:byte(i + k)
    return c ~= nil and c >= 0x80 and c <= 0xBF
  end
  if b >= 0xC2 and b <= 0xDF then
    if is_cont(1) then
      return (b - 0xC0) * 0x40 + (s:byte(i + 1) - 0x80), i + 2
    end
  elseif b >= 0xE0 and b <= 0xEF then
    if is_cont(1) and is_cont(2) then
      local cp = (b - 0xE0) * 0x1000
        + (s:byte(i + 1) - 0x80) * 0x40
        + (s:byte(i + 2) - 0x80)
      if cp >= 0x800 and not (cp >= 0xD800 and cp <= 0xDFFF) then
        return cp, i + 3
      end
    end
  elseif b >= 0xF0 and b <= 0xF4 then
    if is_cont(1) and is_cont(2) and is_cont(3) then
      local cp = (b - 0xF0) * 0x40000
        + (s:byte(i + 1) - 0x80) * 0x1000
        + (s:byte(i + 2) - 0x80) * 0x40
        + (s:byte(i + 3) - 0x80)
      if cp >= 0x10000 and cp <= 0x10FFFF then
        return cp, i + 4
      end
    end
  end
  return nil
end

--- 将 Unicode 码点编码为 JSON \uXXXX 转义（超出 BMP 时输出 UTF-16 代理对）。
local function utf8_codepoint_to_escape(cp)
  if cp >= 0xD800 and cp <= 0xDFFF then
    return "\\ufffd"
  end
  if cp <= 0xFFFF then
    return string.format("\\u%04x", cp)
  end
  local v = cp - 0x10000
  local hi = 0xD800 + math.floor(v / 0x400)
  local lo = 0xDC00 + (v % 0x400)
  return string.format("\\u%04x\\u%04x", hi, lo)
end

--- 安全编码 JSON 字符串：非 ASCII 统一转 \uXXXX，非法 UTF-8 字节替换为 U+FFFD。
local function json_encode_string(s)
  local out = {}
  local i = 1
  local len = #s
  while i <= len do
    local b = s:byte(i)
    if b < 0x80 then
      if b == 0x22 then
        out[#out + 1] = '\\"'
      elseif b == 0x5C then
        out[#out + 1] = "\\\\"
      elseif b == 0x08 then
        out[#out + 1] = "\\b"
      elseif b == 0x0C then
        out[#out + 1] = "\\f"
      elseif b == 0x0A then
        out[#out + 1] = "\\n"
      elseif b == 0x0D then
        out[#out + 1] = "\\r"
      elseif b == 0x09 then
        out[#out + 1] = "\\t"
      elseif b < 0x20 or b == 0x7F then
        out[#out + 1] = string.format("\\u%04x", b)
      else
        out[#out + 1] = string.char(b)
      end
      i = i + 1
    else
      local cp, next_i = utf8_decode_char(s, i)
      if cp then
        out[#out + 1] = utf8_codepoint_to_escape(cp)
        i = next_i
      else
        out[#out + 1] = "\\ufffd"
        i = i + 1
      end
    end
  end
  return '"' .. table.concat(out) .. '"'
end

local function json_encode_value(v)
  local t = type(v)
  if v == nil then
    return "null"
  elseif t == "boolean" then
    return v and "true" or "false"
  elseif t == "number" then
    if v ~= v or v == math.huge or v == -math.huge then
      return "null"
    end
    if math.type and math.type(v) == "integer" then
      return string.format("%d", v)
    end
    return string.format("%.14g", v)
  elseif t == "string" then
    return json_encode_string(v)
  elseif t == "table" then
    if vim.islist(v) then
      local parts = {}
      for i = 1, #v do
        parts[i] = json_encode_value(v[i])
      end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    local parts = {}
    for k, val in pairs(v) do
      if type(k) == "string" then
        parts[#parts + 1] = json_encode_string(k) .. ":" .. json_encode_value(val)
      end
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "null"
end

--- 编码为 JSON 字符串
function json.encode(v)
  return json_encode_value(v)
end

local function json_decode_error(str, pos, msg)
  error(string.format("JSON 解析错误(位置 %d): %s", pos, msg), 0)
end

local function json_skip_ws(str, pos)
  local _, e = str:find("^[ \t\r\n]*", pos)
  return e + 1
end

local decode_value -- 前向声明

local function json_decode_string(str, pos)
  local buf = {}
  local i = pos + 1
  local len = #str
  while i <= len do
    local c = str:sub(i, i)
    if c == '"' then
      return table.concat(buf), i + 1
    elseif c == "\\" then
      local esc = str:sub(i + 1, i + 1)
      if esc == '"' or esc == "\\" or esc == "/" then
        buf[#buf + 1] = esc
        i = i + 2
      elseif esc == "b" then
        buf[#buf + 1] = "\b"
        i = i + 2
      elseif esc == "f" then
        buf[#buf + 1] = "\f"
        i = i + 2
      elseif esc == "n" then
        buf[#buf + 1] = "\n"
        i = i + 2
      elseif esc == "r" then
        buf[#buf + 1] = "\r"
        i = i + 2
      elseif esc == "t" then
        buf[#buf + 1] = "\t"
        i = i + 2
      elseif esc == "u" then
        local code = tonumber(str:sub(i + 2, i + 5), 16)
        if not code then
          json_decode_error(str, i, "非法 \\u 转义")
        end
        i = i + 6
        -- 代理对：高代理项 + 低代理项合成一个码点
        if code >= 0xD800 and code <= 0xDBFF and str:sub(i, i + 1) == "\\u" then
          local lo = tonumber(str:sub(i + 2, i + 5), 16)
          if lo and lo >= 0xDC00 and lo <= 0xDFFF then
            code = 0x10000 + (code - 0xD800) * 0x400 + (lo - 0xDC00)
            i = i + 6
          end
        end
        buf[#buf + 1] = vim.fn.nr2char(code)
      else
        json_decode_error(str, i, "非法转义 \\" .. esc)
      end
    else
      buf[#buf + 1] = c
      i = i + 1
    end
  end
  json_decode_error(str, i, "字符串未闭合")
end

local function json_decode_array(str, pos)
  local arr = {}
  local i = json_skip_ws(str, pos + 1)
  if str:sub(i, i) == "]" then
    return arr, i + 1
  end
  while true do
    local val
    val, i = decode_value(str, i)
    arr[#arr + 1] = val
    i = json_skip_ws(str, i)
    local c = str:sub(i, i)
    if c == "," then
      i = json_skip_ws(str, i + 1)
    elseif c == "]" then
      return arr, i + 1
    else
      json_decode_error(str, i, "数组语法错误")
    end
  end
end

local function json_decode_object(str, pos)
  local obj = {}
  local i = json_skip_ws(str, pos + 1)
  if str:sub(i, i) == "}" then
    return obj, i + 1
  end
  while true do
    if str:sub(i, i) ~= '"' then
      json_decode_error(str, i, "对象键必须是字符串")
    end
    local key
    key, i = json_decode_string(str, i)
    i = json_skip_ws(str, i)
    if str:sub(i, i) ~= ":" then
      json_decode_error(str, i, "对象缺少冒号")
    end
    i = json_skip_ws(str, i + 1)
    local val
    val, i = decode_value(str, i)
    obj[key] = val
    i = json_skip_ws(str, i)
    local c = str:sub(i, i)
    if c == "," then
      i = json_skip_ws(str, i + 1)
    elseif c == "}" then
      return obj, i + 1
    else
      json_decode_error(str, i, "对象语法错误")
    end
  end
end

decode_value = function(str, pos)
  local i = json_skip_ws(str, pos)
  local c = str:sub(i, i)
  if c == "" then
    json_decode_error(str, i, "内容意外结束")
  elseif c == '"' then
    return json_decode_string(str, i)
  elseif c == "{" then
    return json_decode_object(str, i)
  elseif c == "[" then
    return json_decode_array(str, i)
  elseif c == "t" then
    if str:sub(i, i + 3) == "true" then
      return true, i + 4
    end
    json_decode_error(str, i, "非法字面量")
  elseif c == "f" then
    if str:sub(i, i + 4) == "false" then
      return false, i + 5
    end
    json_decode_error(str, i, "非法字面量")
  elseif c == "n" then
    if str:sub(i, i + 3) == "null" then
      return nil, i + 4
    end
    json_decode_error(str, i, "非法字面量")
  elseif c == "-" or c:match("%d") then
    local num = str:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
    if not num then
      json_decode_error(str, i, "非法数字")
    end
    return tonumber(num), i + #num
  else
    json_decode_error(str, i, "意外的字符 '" .. c .. "'")
  end
end

--- 解码 JSON 文本；失败或非法输入返回 nil
function json.decode(str)
  if type(str) ~= "string" or str == "" then
    return nil
  end
  local ok, val = pcall(decode_value, str, 1)
  if not ok then
    return nil
  end
  return val
end

-- 暴露给测试/调试
M._json = json

-- ========== curl 异步 POST ==========

--- 异步发送 JSON POST 请求
--- @param url string 完整 URL
--- @param headers table 请求头
--- @param body string 请求体（JSON 字符串）
--- @param timeout_ms number 超时（毫秒）
--- @param callback fun(ok:boolean, data:string|nil, err:string|nil, status:number|nil)
local function http_post_json(url, headers, body, timeout_ms, callback)
  if vim.fn.executable("curl") ~= 1 then
    callback(false, nil, "未找到 curl 可执行文件")
    return
  end

  -- 临时文件：请求体走 --data-binary @file（避免 shell 转义与参数长度限制），
  -- 响应体 -o file，HTTP 状态码经 -w 输出到 stdout。
  local tmp = vim.fn.tempname()
  local body_file = tmp .. ".body"
  local resp_file = tmp .. ".resp"

  local bf = io.open(body_file, "wb")
  if not bf then
    callback(false, nil, "无法写入临时请求文件")
    return
  end
  bf:write(body)
  bf:close()

  local args = {
    "curl",
    "-sS",
    "--no-buffer",
    "--max-time",
    tostring(math.max(1, math.ceil((timeout_ms or 60000) / 1000))),
    "-X",
    "POST",
    "-o",
    resp_file,
    "--data-binary",
    "@" .. body_file,
    "-w",
    "%{http_code}",
  }
  for k, v in pairs(headers or {}) do
    args[#args + 1] = "-H"
    args[#args + 1] = k .. ": " .. tostring(v)
  end
  args[#args + 1] = url

  local stdout_chunks = {}
  local stderr_chunks = {}

  local function cleanup()
    pcall(vim.fn.delete, body_file)
    pcall(vim.fn.delete, resp_file)
  end

  local job_id = vim.fn.jobstart(args, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      for _, line in ipairs(data or {}) do
        if line ~= "" then
          stdout_chunks[#stdout_chunks + 1] = line
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data or {}) do
        if line ~= "" then
          stderr_chunks[#stderr_chunks + 1] = line
        end
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        local resp_body = ""
        local rf = io.open(resp_file, "rb")
        if rf then
          resp_body = rf:read("*a") or ""
          rf:close()
        end
        cleanup()

        local status = tonumber(table.concat(stdout_chunks, ""):match("(%d%d%d)%s*$") or "")
        local stderr_text = table.concat(stderr_chunks, "\n")

        if code ~= 0 and resp_body == "" then
          callback(false, nil, stderr_text ~= "" and stderr_text or ("curl 退出码 " .. tostring(code)), status)
          return
        end
        callback(true, resp_body, nil, status)
      end)
    end,
  })

  if job_id <= 0 then
    cleanup()
    callback(false, nil, "无法启动 curl 进程")
  end
end

--- 清洗 AI 返回的提交信息：去引号/代码块/多余空白，并限制长度。
--- @param content any
--- @return string|nil
local function clean_content(content)
  if type(content) ~= "string" then
    return nil
  end
  -- 去首尾引号与空白
  local s = content:gsub("^[\"']+", ""):gsub("[\"']+$", "")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  -- 去 markdown 代码块围栏标记（只去标记，保留内容，避免整段被删空）
  s = s:gsub("```[^\n]*\n?", "")
  s = s:gsub("```", "")
  -- 去内联反引号（保留内部文字）
  s = s:gsub("`([^`]*)`", "%1")
  -- 折叠空白：多行合并为单行
  s = s:gsub("%s+", " ")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  -- 去掉常见前缀噪声
  s = s:gsub("^提交信息[:：]%s*", "")
  s = s:gsub("^commit message[:：]%s*", "")
  s = s:gsub("^提交信息%s*", "")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  if s == "" then
    return nil
  end
  -- 限制长度（conventional commit 建议 ≤ 72）
  if vim.fn.strchars(s) > 72 then
    s = vim.fn.strcharpart(s, 0, 72)
  end
  return s
end

local function safe_shell_escape(str)
  -- 安全的 shell 转义函数，专门处理 git commit 信息
  if not str then
    return ""
  end
  -- 转义单引号、双引号和反斜杠
  local escaped = str:gsub("'", "'\\''")
  escaped = escaped:gsub('"', '\\"')
  escaped = escaped:gsub("\\", "\\\\")
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
    local add_result = vim.fn.system("git add -A")
    local add_exit_code = vim.v.shell_error

    if add_exit_code ~= 0 then
      return false, "git add 失败: " .. add_result
    end

    -- 然后执行 git commit -m
    cmd = string.format("git commit -m %s", safe_shell_escape(message))
  else
    -- 只提交已暂存的更改
    cmd = string.format("git commit -m %s", safe_shell_escape(message))
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

  -- 自建请求：OpenAI 兼容协议（POST {base_url}/chat/completions，Bearer 鉴权），
  -- 不依赖 NeoAI；配置见文件顶部 config，可用 M.configure()/M.setup({...}) 覆盖。
  if not config.api_key or config.api_key == "" then
    vim.notify("未配置 API Key（COMMIT_AI_API_KEY / DEEPSEEK_API_KEY），使用备用方案", vim.log.levels.WARN)
    generate_fallback_commit_message(diff_output, callback)
    return
  end

  local model = config.model
  if model == "auto" or model == "" or model == nil then
    model = "deepseek-chat"
  end

  local url = config.base_url:gsub("/+$", "") .. "/chat/completions"
  local headers = {
    ["Content-Type"] = "application/json",
    ["Authorization"] = "Bearer " .. config.api_key,
  }
  local body = json.encode({
    model = model,
    messages = {
      {
        role = "system",
        content = "你是一个专业的 Git 提交信息生成助手，擅长根据代码变更生成简洁、规范的中文 commit message。",
      },
      { role = "user", content = prompt },
    },
    temperature = config.temperature,
    max_tokens = config.max_tokens,
    stream = false,
  })

  local function fail(msg)
    vim.notify("AI 请求失败: " .. tostring(msg or "未知错误"), vim.log.levels.ERROR)
    generate_fallback_commit_message(diff_output, callback)
  end

  -- 简单指数退避重试（仅对网络/服务端错误重试，4xx 直接失败）
  local attempt = 0
  local max_attempts = math.max(0, config.max_retries or 0) + 1

  local function do_request()
    attempt = attempt + 1
    http_post_json(url, headers, body, config.timeout_ms, function(ok, data, err, status)
      if not ok then
        if attempt < max_attempts and (not status or status >= 500) then
          vim.defer_fn(do_request, 300 * attempt)
          return
        end
        fail(err)
        return
      end

      local parsed = json.decode(data)
      if not parsed then
        fail("响应解析失败: " .. tostring(data):sub(1, 200))
        return
      end

      if parsed.error then
        local emsg = type(parsed.error) == "table" and parsed.error.message or parsed.error
        fail(tostring(emsg))
        return
      end

      local choice = parsed.choices and parsed.choices[1]
      local raw = choice and choice.message and choice.message.content or nil
      local content = clean_content(raw)
      if content then
        callback(content)
      else
        vim.notify("AI 返回内容为空，使用备用方案", vim.log.levels.WARN)
        generate_fallback_commit_message(diff_output, callback)
      end
    end)
  end

  do_request()
end

--- 注册快捷键。可选传入配置覆盖默认值，例如：
--- M.setup({ api_key = "sk-xxx", model = "deepseek-chat", base_url = "https://api.deepseek.com" })
--- @param opts table|nil
function M.setup(opts)
  M.configure(opts)
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
                    vim.notify(
                      "✓ AI 提交成功: " .. commit_hash_or_error:sub(1, 8) .. " - " .. final_input,
                      vim.log.levels.INFO
                    )
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
end

return M
