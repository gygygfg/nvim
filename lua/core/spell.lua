-- 自动拼写纠正配置

local M = {}

-- 默认配置
local default_config = {
  enabled = false, -- 禁用拼写纠正
  languages = { "en_us" },
  auto_correct_on_tab = false, -- 禁用按 Tab 时自动纠正
  camel_case = true,
  max_suggestions = 5,

  -- 文件类型配置
  enable_for = { "markdown", "text", "gitcommit", "latex", "tex", "rst" },
  disable_for = { "lua", "python", "javascript", "typescript", "java", "cpp", "c", "go", "rust" },
}

-- 当前配置
local config = vim.tbl_deep_extend("force", default_config, {})

-- 设置配置
function M.setup(user_config)
  config = vim.tbl_deep_extend("force", default_config, user_config or {})
  M.config = config

  -- 应用基本拼写设置
  vim.opt.spelllang = table.concat(config.languages, ",")
  vim.opt.spellsuggest = "best"

  if config.camel_case then
    vim.opt.spelloptions = "camel"
  end

  -- 设置自动命令
  M.setup_autocmds()
end

-- 检查单词是否拼写错误
function M.is_spell_error(word)
  if word == "" then
    return false
  end
  local spell_bad = vim.fn.spellbadword(word)
  return spell_bad[1] ~= ""
end

-- 获取拼写建议
function M.get_suggestions(word, count)
  if word == "" then
    return {}
  end
  count = count or config.max_suggestions
  return vim.fn.spellsuggest(word, count)
end

-- 获取光标下单词的边界（起始列、结束列），col 是 0-based
local function get_word_boundaries(line, col)
  -- 从光标位置向左找单词起始
  local start_col = col
  for i = col, 0, -1 do
    local ch = line:sub(i + 1, i + 1)
    if ch:match("%w") then
      start_col = i
    else
      break
    end
  end

  -- 从光标位置向右找单词结束
  local end_col = col
  for i = col, #line - 1 do
    local ch = line:sub(i + 1, i + 1)
    if ch:match("%w") then
      end_col = i
    else
      break
    end
  end

  return start_col, end_col
end

-- 自动纠正当前单词（使用第一个建议）
function M.auto_correct_current_word()
  -- 先尝试命令模式处理
  local cmdline = vim.fn.getcmdline()
  if cmdline ~= "" then
    local cmdpos = vim.fn.getcmdpos() -- getcmdpos 是 1-based

    -- getcmdpos 返回 1-based 位置，光标在单词末尾时 = #cmdline + 1
    local pos = math.min(cmdpos, #cmdline)
    if pos < 1 then
      pos = 1
    end

    -- 在命令行中找到光标所在单词的起始位置
    local word_start = pos
    for i = pos, 1, -1 do
      local ch = cmdline:sub(i, i)
      if ch:match("%w") then
        word_start = i
      else
        break
      end
    end

    -- 找到单词结束位置
    local word_end = pos
    for i = pos, #cmdline do
      local ch = cmdline:sub(i, i)
      if ch:match("%w") then
        word_end = i
      else
        break
      end
    end

    -- 提取光标下的完整单词
    local cursor_word = cmdline:sub(word_start, word_end)
    if cursor_word ~= "" then
      -- 优先尝试拼写建议
      local sug = M.get_suggestions(cursor_word, 1)
      if #sug > 0 then
        local new_cmdline = cmdline:sub(1, word_start - 1) .. sug[1] .. cmdline:sub(word_end + 1)
        vim.fn.setcmdline(new_cmdline)
        vim.fn.setcmdpos(word_start - 1 + #sug[1] + 1)
        return true
      end

      -- 拼写建议为空时，尝试命令名模糊匹配（仅在 : 命令行）
      local cmdtype = vim.fn.getcmdtype()
      if cmdtype == ":" then
        -- 获取所有可用命令
        local all_cmds = vim.api.nvim_get_commands({})
        local best_match = nil
        local best_score = math.huge

        local lower_word = cursor_word:lower()
        for cmd_name, _ in pairs(all_cmds) do
          -- 跳过很长的命令名
          if #cmd_name <= 30 then
            -- 计算简单的 Levenshtein 距离
            local dist = M._levenshtein(lower_word, cmd_name:lower())
            if dist < best_score and dist <= 2 then -- 最多容忍2个字符差异
              best_score = dist
              best_match = cmd_name
            end
          end
        end

        if best_match and best_score < math.huge then
          local new_cmdline = cmdline:sub(1, word_start - 1) .. best_match .. cmdline:sub(word_end + 1)
          vim.fn.setcmdline(new_cmdline)
          vim.fn.setcmdpos(word_start - 1 + #best_match + 1)
          return true
        end
      end
    end
    return false
  end

  -- 插入/普通模式：不依赖 spell 开关，直接尝试获取建议
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return false
  end

  -- 始终尝试获取拼写建议（不检查 is_spell_error，因为 spell 可能未启用）
  local suggestions = M.get_suggestions(word, 1)
  if #suggestions > 0 then
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1
    local col = cursor[2]
    local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]

    local start_col, end_col = get_word_boundaries(line, col)

    local new_line = line:sub(1, start_col) .. suggestions[1] .. line:sub(end_col + 1)
    vim.api.nvim_buf_set_lines(0, row, row + 1, false, { new_line })
    vim.api.nvim_win_set_cursor(0, { row + 1, start_col + #suggestions[1] })
    return true
  end

  return false
end

-- Levenshtein 距离（用于命令模糊匹配）
function M._levenshtein(s, t)
  local s_len, t_len = #s, #t
  if s_len == 0 then return t_len end
  if t_len == 0 then return s_len end

  local prev = {}
  local curr = {}
  for i = 0, t_len do
    prev[i] = i
  end

  for i = 1, s_len do
    curr[0] = i
    local s_i = s:sub(i, i)
    for j = 1, t_len do
      local cost = s_i == t:sub(j, j) and 0 or 1
      curr[j] = math.min(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost)
    end
    prev, curr = curr, prev
  end

  return prev[t_len]
end

-- 智能 Tab 处理：自动纠正或显示建议
function M.smart_tab_handler()
  if not config.auto_correct_on_tab then
    return false
  end

  local word = vim.fn.expand("<cword>")
  if word == "" then
    return false
  end

  if M.is_spell_error(word) then
    -- 尝试自动纠正
    if M.auto_correct_current_word() then
      return true
    end
    -- 如果自动纠正失败，显示建议菜单
    vim.api.nvim_feedkeys("<Esc>z=", "n", true)
    return true
  end

  return false
end

-- 设置自动命令
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("AutoSpellCorrection", { clear = true })

  -- 在特定文件类型中自动启用拼写检查
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = config.enable_for,
    callback = function()
      vim.opt_local.spell = true
    end,
  })

  -- 在代码文件中自动禁用拼写检查
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = config.disable_for,
    callback = function()
      vim.opt_local.spell = false
    end,
  })

  -- 在普通文件中默认启用拼写检查
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      local ft = vim.bo.filetype
      local is_enabled = false

      -- 检查是否在启用列表中
      for _, pattern in ipairs(config.enable_for) do
        if ft == pattern then
          is_enabled = true
          break
        end
      end

      -- 检查是否在禁用列表中
      for _, pattern in ipairs(config.disable_for) do
        if ft == pattern then
          is_enabled = false
          break
        end
      end

      -- 如果既不在启用列表也不在禁用列表，默认启用
      if ft == "" then
        is_enabled = true
      end

      vim.opt_local.spell = is_enabled
    end,
  })
end

-- 导出模块
return M
