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
      local cp = (b - 0xE0) * 0x1000 + (s:byte(i + 1) - 0x80) * 0x40 + (s:byte(i + 2) - 0x80)
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

--- 清洗 AI 返回的提交信息：去引号/代码块/多余空白。
--- 注意：此处不截断长度，长度约束只写在提示词里，模型真返回长文本也原样保留。
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

-- ========== 变更上下文提取（按重要性挑选 diff，避免被文档淹没） ==========

local DOC_EXTS = { md = true, markdown = true, rst = true, adoc = true, org = true, tex = true }
local CONFIG_EXTS = {
  json = true,
  jsonc = true,
  yaml = true,
  yml = true,
  toml = true,
  ini = true,
  conf = true,
  cfg = true,
  env = true,
}
local NOISE_FILES = {
  ["package-lock.json"] = true,
  ["pnpm-lock.yaml"] = true,
  ["yarn.lock"] = true,
  ["go.sum"] = true,
  ["cargo.lock"] = true,
  ["poetry.lock"] = true,
  ["nvim-pack-lock.json"] = true,
}
local KIND_LABEL = { code = "代码", test = "测试", config = "配置", doc = "文档", noise = "锁/生成" }
local KIND_ORDER = { code = 1, test = 2, config = 3, doc = 4, noise = 5 }

--- 执行 git 命令，成功返回输出（可能为空串），失败返回 nil
local function git_capture(args)
  local out = vim.fn.system("git " .. args)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out
end

--- 收集本次变更的 diff / stat / name-status
--- @param include_unstaged boolean 是否包含未暂存改动
--- @return table|nil { base, stat, diff, name_status }
local function collect_changes(include_unstaged)
  -- 优先暂存区；暂存区为空时回落到工作区（与原行为一致）
  local bases = include_unstaged and { "HEAD" } or { "--cached", "" }
  for _, base in ipairs(bases) do
    local prefix = base == "" and "diff" or ("diff " .. base)
    local stat = git_capture(prefix .. " --stat")
    if stat and stat ~= "" then
      return {
        base = base,
        stat = stat,
        diff = git_capture(prefix) or "",
        name_status = git_capture(prefix .. " --name-status") or "",
      }
    end
  end
  return nil
end

--- 文件类别：code | test | config | doc | noise
local function classify_path(path)
  local lower = path:lower()
  local name = lower:match("([^/]+)$") or lower
  local ext = name:match("%.([%w_]+)$")

  if
    NOISE_FILES[name]
    or lower:match("/vendor/")
    or lower:match("/dist/")
    or lower:match("/node_modules/")
    or lower:match("%.min%.[a-z]+$")
    or lower:match("%.lock$")
  then
    return "noise"
  end
  if ext and DOC_EXTS[ext] then
    return "doc"
  end
  if
    lower:match("^docs?/")
    or lower:match("/docs?/")
    or name:match("^readme")
    or name:match("^changelog")
    or name:match("^license")
  then
    return "doc"
  end
  if lower:match("test") or lower:match("spec") then
    return "test"
  end
  if ext and CONFIG_EXTS[ext] then
    return "config"
  end
  return "code"
end

--- 解析 git diff --stat，返回文件列表（含改动行数）
local function parse_stat(stat)
  local files = {}
  for line in (stat or ""):gmatch("[^\n]+") do
    local path, changed = line:match("^%s*(.-)%s*|%s*(%d+)")
    if not path then
      local bin_path = line:match("^%s*(.-)%s*|%s*Bin")
      if bin_path and bin_path ~= "" then
        path, changed = bin_path, 0
      end
    end
    if path and path ~= "" and not path:match("changed") then
      files[#files + 1] = { path = (path:gsub('"', "")), changed = tonumber(changed) or 0 }
    end
  end
  return files
end

--- 按 `diff --git` 切分，返回 path -> 单文件 diff 文本
local function split_diff_by_file(diff)
  local map = {}
  local current
  for line in (diff .. "\n"):gmatch("([^\n]*)\n") do
    local header_path = line:match("^diff %-%-git .-%sb/(.+)$")
    if header_path then
      if current then
        map[current.path] = table.concat(current.buf, "\n")
      end
      current = { path = header_path, buf = { line } }
    elseif current then
      current.buf[#current.buf + 1] = line
    end
  end
  if current then
    map[current.path] = table.concat(current.buf, "\n")
  end
  return map
end

--- 从 --name-status 提取新增文件集合
local function parse_new_files(name_status)
  local added = {}
  for line in (name_status or ""):gmatch("[^\n]+") do
    local status, path = line:match("^(%u)%s+(.+)$")
    if status == "A" and path then
      added[path] = true
    end
  end
  return added
end

--- 组装喂给模型的变更上下文，并给出本地分析结论
--- @return table { text, files, has_code, doc_only, new_files, suggested_type }
local function build_change_context(changes)
  local files = parse_stat(changes.stat)
  local added = parse_new_files(changes.name_status)
  local diff_map = split_diff_by_file(changes.diff or "")

  local weight = { code = 0, test = 0, config = 0, doc = 0, noise = 0 }
  for _, f in ipairs(files) do
    f.kind = classify_path(f.path)
    f.is_new = added[f.path] == true
    weight[f.kind] = weight[f.kind] + f.changed
  end

  -- 排序：代码/测试优先，同类按改动量降序
  table.sort(files, function(a, b)
    local oa, ob = KIND_ORDER[a.kind] or 9, KIND_ORDER[b.kind] or 9
    if oa ~= ob then
      return oa < ob
    end
    if a.changed ~= b.changed then
      return a.changed > b.changed
    end
    return a.path < b.path
  end)

  local has_code = weight.code > 0 or weight.test > 0
  local doc_only = (weight.code + weight.test + weight.config) == 0 and weight.doc > 0

  local suggested_type
  if doc_only then
    suggested_type = "docs"
  elseif weight.test > 0 and weight.test >= weight.code then
    suggested_type = "test"
  elseif not has_code and weight.config > 0 then
    suggested_type = "chore"
  elseif has_code then
    for _, f in ipairs(files) do
      if f.is_new and f.kind == "code" then
        suggested_type = "feat"
        break
      end
    end
  end

  -- 概览：全量文件（最多 60 行）按重要性列出，让模型先看到全局
  local overview = {}
  for i, f in ipairs(files) do
    if i > 60 then
      overview[#overview + 1] = string.format("- …… 其余 %d 个文件略", #files - i + 1)
      break
    end
    overview[#overview + 1] = string.format(
      "- %s%s（%s，约 %d 行）",
      f.path,
      f.is_new and " [新增]" or "",
      KIND_LABEL[f.kind] or "其他",
      f.changed
    )
  end

  -- 细节：有代码改动时只展开代码/测试/配置，文档仅列路径（关键：避免文档 diff 挤掉代码）
  local detail_files = {}
  for _, f in ipairs(files) do
    if f.kind ~= "noise" then
      if has_code or weight.config > 0 then
        if f.kind ~= "doc" then
          detail_files[#detail_files + 1] = f
        end
      elseif f.kind == "doc" then
        detail_files[#detail_files + 1] = f
      end
    end
  end

  local total_budget = has_code and 6000 or 3000
  local per_file_budget = has_code and 1800 or 1200
  local used = 0
  local details = {}
  for _, f in ipairs(detail_files) do
    local block = diff_map[f.path]
    if block then
      if used >= total_budget then
        break
      end
      local clipped = block
      if vim.fn.strchars(clipped) > per_file_budget then
        clipped = vim.fn.strcharpart(clipped, 0, per_file_budget) .. "\n... （该文件 diff 已截断）"
      end
      if used + vim.fn.strchars(clipped) > total_budget then
        clipped = vim.fn.strcharpart(clipped, 0, math.max(0, total_budget - used))
          .. "\n... （已达总长度上限，后续文件略）"
        details[#details + 1] = clipped
        used = total_budget
        break
      end
      details[#details + 1] = clipped
      used = used + vim.fn.strchars(clipped)
    end
  end
  if #details == 0 then
    -- 兜底：按文件切分失败时退化为整体截断
    details[1] = vim.fn.strcharpart(changes.diff or "", 0, total_budget)
  end

  local doc_paths = {}
  if has_code then
    for _, f in ipairs(files) do
      if f.kind == "doc" then
        doc_paths[#doc_paths + 1] = f.path
      end
    end
  end

  local parts = { "## 变更概览（按重要性排序）", table.concat(overview, "\n") }
  if #doc_paths > 0 then
    parts[#parts + 1] =
      string.format("\n## 顺带修改的文档（共 %d 个，diff 从略）：%s", #doc_paths, table.concat(doc_paths, ", "))
  end
  parts[#parts + 1] = "\n## 改动细节（diff）\n" .. table.concat(details, "\n\n")

  return {
    text = table.concat(parts, "\n"),
    files = files,
    has_code = has_code,
    doc_only = doc_only,
    new_files = added,
    suggested_type = suggested_type,
  }
end

--- 构建提示词（刻意不给 docs 之类的示例句，避免示例锚定）
local function build_commit_prompt(ctx)
  local type_table = table.concat({
    "feat=新增功能或能力",
    "fix=修复缺陷或错误行为",
    "refactor=不改变行为的重构",
    "perf=性能优化",
    "test=测试相关",
    "docs=仅文档或注释说明",
    "chore=构建/依赖/配置/杂务",
    "style=纯格式调整",
    "ci=流水线脚本",
  }, "；")

  local lines = {
    "请阅读下面这次 Git 变更，生成一条中文 conventional commit 提交信息。",
    "",
    ctx.text,
    "",
    "## 输出规则",
    "1. type 只由「主要改动」决定：以概览中改动量最大、且属于代码/测试/配置的文件为准，不要被顺带修改的文档带偏。",
    "2. 可选 type：" .. type_table .. "。",
    "3. 只要涉及代码文件（.lua/.js/.py/.go 等）的改动，就禁止使用 docs；仅当全部改动都是文档时才可用 docs。",
    "4. 描述必须具体：点明被改动的模块、函数、配置项或行为，禁止「更新文档」「更新代码」「优化代码」「若干修改」这类空话。",
    "5. 有明确模块名时加 scope，取所在目录或子系统名（如 sandbox / chat / commit / ui）。",
    "6. 只输出一行 `type(scope): 描述` 或 `type: 描述`：中文、总长不超过 50 字、不带引号、不带代码块、不带句号、不做解释。",
  }

  if ctx.has_code then
    lines[#lines + 1] =
      "\n## 本次硬约束\n本次变更包含代码文件，type 必须从 feat / fix / refactor / perf / test / chore / style / build / ci 中选择，禁止使用 docs。"
  elseif ctx.doc_only then
    lines[#lines + 1] = "\n## 本次硬约束\n本次变更只涉及文档，type 必须是 docs。"
  end
  if ctx.suggested_type then
    lines[#lines + 1] =
      string.format("（本地静态分析倾向 type=%s，仅供参考，与你的判断不符时可覆盖。）", ctx.suggested_type)
  end
  lines[#lines + 1] = "\n提交信息："

  return table.concat(lines, "\n")
end

local VALID_TYPES = {
  feat = true,
  fix = true,
  refactor = true,
  perf = true,
  test = true,
  docs = true,
  chore = true,
  style = true,
  build = true,
  ci = true,
  revert = true,
}

--- 取第一处非空行（模型偶尔会输出解释或多行）
local function first_line(text)
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed ~= "" and not trimmed:match("^```") then
      return trimmed
    end
  end
  return ""
end

--- 无 type 时按描述措辞兜底推断
local function guess_type_from_desc(desc)
  local d = (desc or ""):lower()
  if d:match("修复") or d:match("修正") or d:match("解决") or d:match("bug") then
    return "fix"
  end
  if d:match("新增") or d:match("添加") or d:match("实现") or d:match("支持") then
    return "feat"
  end
  if d:match("重构") or d:match("拆分") or d:match("重命名") or d:match("整理") then
    return "refactor"
  end
  if d:match("性能") or d:match("加速") then
    return "perf"
  end
  if d:match("测试") then
    return "test"
  end
  return nil
end

--- 依据变更文件列表生成兜底描述（凑不出具体内容时用）
local function describe_by_files(ctx)
  local top, total = nil, 0
  for _, f in ipairs(ctx.files or {}) do
    if f.kind ~= "noise" then
      total = total + 1
      if not top then
        top = f
      end
    end
  end
  if not top then
    return "更新变更文件"
  end
  local base = top.path:gsub("^.*/", "")
  if total <= 1 then
    return "调整 " .. base
  end
  return string.format("调整 %s 等 %d 个文件", base, total)
end

--- 是否为空泛描述（这类描述一律视为无效，需替换为具体内容）
local function is_vague_desc(desc)
  local d = (desc or ""):gsub("[。%.%s]+$", ""):lower()
  if vim.fn.strchars(d) < 4 then
    return true
  end
  for _, vague in ipairs({
    "更新文档",
    "更新代码",
    "更新内容",
    "更新文件",
    "修改代码",
    "优化代码",
    "代码更新",
    "文档更新",
    "若干修改",
    "一些修改",
    "update",
    "update files",
    "update docs",
    "misc",
  }) do
    if d == vague then
      return true
    end
  end
  return false
end

--- 解析出 (type, scope, desc)；type 非法时 type 为 nil
local function split_commit_message(msg)
  local typ, scope, desc = msg:match("^(%a+)(%b())%s*[:：]%s*(.+)$")
  if not typ then
    typ, desc = msg:match("^(%a+)%s*[:：]%s*(.+)$")
    scope = nil
  end
  if typ then
    typ = typ:lower()
    if not VALID_TYPES[typ] then
      return nil, nil, msg
    end
    return typ, scope, desc
  end
  return nil, nil, msg
end

--- 规范化 AI 输出；need_retry 表示「含代码改动却标了 docs」，需带强约束重试一次
local function normalize_commit_message(raw, ctx)
  local msg = clean_content(first_line(raw or ""))
  if not msg then
    return nil, false
  end

  local typ, scope, desc = split_commit_message(msg)
  local need_retry = false

  if not typ then
    desc = desc:gsub("^%a+%s*[:：]%s*", "")
    local fallback_type = ctx.suggested_type
      or guess_type_from_desc(desc)
      or (ctx.has_code and "chore" or "docs")
    msg = fallback_type .. ": " .. desc
  else
    need_retry = (typ == "docs") and not ctx.doc_only
    msg = typ .. (scope or "") .. ": " .. desc
  end

  msg = msg:gsub("[。%.!！%s]+$", "")
  -- 不截断 AI 返回的提交信息（长度只由提示词约束）
  return msg, need_retry
end

--- 重试后仍是 docs 时，按本地分析强制纠正 type
local function force_commit_type(msg, ctx)
  local typ, scope, desc = split_commit_message(msg)
  if typ and typ ~= "docs" then
    return msg
  end
  local desc_text = (typ and desc) or msg
  if is_vague_desc(desc_text) then
    desc_text = describe_by_files(ctx)
  end
  local new_type = ctx.suggested_type or guess_type_from_desc(desc_text) or (ctx.has_code and "chore" or "docs")
  return new_type .. (scope or "") .. ": " .. desc_text
end

--- 备用方案：本地规则生成提交信息（API 不可用或返回异常时）
local function generate_fallback_commit_message(ctx, callback)
  local commit_type = ctx.suggested_type or (ctx.has_code and "chore" or "docs")
  local ai_message = commit_type .. ": " .. describe_by_files(ctx)
  if vim.fn.strchars(ai_message) > 50 then
    ai_message = vim.fn.strcharpart(ai_message, 0, 50)
  end

  callback(ai_message)
end

function M.generate_ai_commit_message(callback, options)
  -- AI 提交信息生成函数
  options = options or {}
  local include_unstaged = options.include_unstaged or false

  -- 关键修复：旧实现只截取 `git diff` 的前 2000 字符，而 git diff 按路径排序，
  -- README/docs 往往排在 lua/ 等代码目录之前，导致模型只看得到文档改动 → 输出清一色的 docs:。
  -- 现在改为：先按「代码优先」重排文件、再挑选 diff 片段，文档改动只列路径。
  local changes = collect_changes(include_unstaged)
  if not changes then
    vim.notify("没有检测到 git 更改", vim.log.levels.WARN)
    callback(nil)
    return
  end

  local ctx = build_change_context(changes)
  local prompt = build_commit_prompt(ctx)

  -- 自建请求：OpenAI 兼容协议（POST {base_url}/chat/completions，Bearer 鉴权），
  -- 不依赖 NeoAI；配置见文件顶部 config，可用 M.configure()/M.setup({...}) 覆盖。
  if not config.api_key or config.api_key == "" then
    vim.notify("未配置 API Key（COMMIT_AI_API_KEY / DEEPSEEK_API_KEY），使用备用方案", vim.log.levels.WARN)
    generate_fallback_commit_message(ctx, callback)
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
  local system_content = config.system_prompt
    or "你是资深工程师，负责把 Git 变更总结成规范的中文 conventional commit 提交信息。严格遵守用户给出的类型规则与输出格式：只输出一行提交信息，不解释、不寒暄、不使用代码块。"

  --- 发起一次请求（extra_rule 用于「类型跑偏」时的纠正型重试）
  local function request(extra_rule, on_done)
    local user_content = prompt
    if extra_rule and extra_rule ~= "" then
      user_content = prompt .. "\n\n## 补充要求（必须遵守）\n" .. extra_rule
    end

    local body = json.encode({
      model = model,
      messages = {
        { role = "system", content = system_content },
        { role = "user", content = user_content },
      },
      temperature = config.temperature,
      max_tokens = config.max_tokens,
      stream = false,
    })

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
          on_done(nil, err)
          return
        end

        local parsed = json.decode(data)
        if not parsed then
          on_done(nil, "响应解析失败: " .. tostring(data):sub(1, 200))
          return
        end

        if parsed.error then
          local emsg = type(parsed.error) == "table" and parsed.error.message or parsed.error
          on_done(nil, tostring(emsg))
          return
        end

        local choice = parsed.choices and parsed.choices[1]
        on_done(choice and choice.message and choice.message.content or nil, nil)
      end)
    end

    do_request()
  end

  request(nil, function(raw, err)
    if not raw then
      vim.notify("AI 请求失败: " .. tostring(err or "未知错误") .. "，使用备用方案", vim.log.levels.ERROR)
      generate_fallback_commit_message(ctx, callback)
      return
    end

    local msg, need_retry = normalize_commit_message(raw, ctx)
    if not msg then
      vim.notify("AI 返回内容为空，使用备用方案", vim.log.levels.WARN)
      generate_fallback_commit_message(ctx, callback)
      return
    end

    if need_retry then
      -- 明明含代码改动却写了 docs：带上强约束重试一次
      local main_file = (ctx.files[1] and ctx.files[1].path) or "代码文件"
      local main_changed = (ctx.files[1] and ctx.files[1].changed) or 0
      local hint = string.format(
        "上一次输出用了 docs，但本次变更包含代码改动（主要文件：%s，约 %d 行）。请重新输出：type 不得为 docs，必须是 feat/fix/refactor/perf/test/chore 之一，描述要写清具体改了什么。",
        main_file,
        main_changed
      )
      request(hint, function(raw2)
        local msg2, still_docs = normalize_commit_message(raw2 or "", ctx)
        if not msg2 or still_docs then
          msg2 = force_commit_type(msg2 or msg, ctx)
        end
        callback(msg2)
      end)
      return
    end

    callback(msg)
  end)
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

-- 暴露内部实现，便于调试与测试（例如观察生成的 prompt、验证类型推断）
M._internal = {
  collect_changes = collect_changes,
  classify_path = classify_path,
  parse_stat = parse_stat,
  split_diff_by_file = split_diff_by_file,
  build_change_context = build_change_context,
  build_commit_prompt = build_commit_prompt,
  normalize_commit_message = normalize_commit_message,
  force_commit_type = force_commit_type,
  generate_fallback_commit_message = generate_fallback_commit_message,
}

return M
