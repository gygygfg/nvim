-- 自动拼写纠正配置

local M = {}

-- 默认配置
local default_config = {
  enabled = false,  -- 禁用拼写纠正
  languages = { "en_us" },
  auto_correct_on_tab = false,  -- 禁用按 Tab 时自动纠正
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

-- 自动纠正当前单词（使用第一个建议）
function M.auto_correct_current_word()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return false
  end
  
  if M.is_spell_error(word) then
    local suggestions = M.get_suggestions(word, 1)
    if #suggestions > 0 then
      -- 使用第一个建议替换当前单词
      vim.api.nvim_feedkeys("<Esc>ciw" .. suggestions[1] .. "<Esc>", "n", true)
      return true
    end
  end
  
  return false
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