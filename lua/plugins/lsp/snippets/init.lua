local M = {}

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

-- 存储已加载的目录，避免重复加载
local loaded_dirs = {}

-- 获取当前文件的目录
local function get_current_file_dir()
  local file_path = vim.fn.expand("%:p")
  if file_path == "" then
    return nil
  end
  return vim.fn.fnamemodify(file_path, ":h")
end

-- 检查并加载当前目录的片段
local function load_current_dir_snippets()
  local current_dir = get_current_file_dir()
  if not current_dir then
    return
  end

  -- 如果已经加载过，跳过
  if loaded_dirs[current_dir] then
    return
  end

  -- 检查当前目录下是否有对应文件类型的片段文件
  local filetype = vim.bo.filetype
  if filetype == "" then
    return
  end

  local snippet_files = {
    current_dir .. "/snippets/" .. filetype .. ".lua",
    current_dir .. "/.snippets/" .. filetype .. ".lua",
    current_dir .. "/" .. filetype .. "_snippets.lua",
  }

  for _, file_path in ipairs(snippet_files) do
    if vim.fn.filereadable(file_path) == 1 then
      -- 安全地加载片段文件
      local ok, snippets = pcall(dofile, file_path)
      if ok and snippets then
        ls.add_snippets(filetype, snippets, {
          key = "dir_" .. current_dir, -- 使用目录作为key，避免冲突
          type = "snippets"
        })
        loaded_dirs[current_dir] = true
        vim.notify("已加载目录片段: " .. file_path)
        break
      else
        vim.notify("加载片段文件失败: " .. file_path, vim.log.levels.WARN)
      end
    end
  end
end

-- 自动命令：在打开文件时加载当前目录的片段
local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("DynamicSnippets", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
    group = group,
    pattern = "*",
    callback = function()
      vim.defer_fn(load_current_dir_snippets, 100) -- 延迟加载，避免影响启动速度
    end
  })

  -- 清除已加载目录的缓存
  vim.api.nvim_create_autocmd("VimLeave", {
    group = group,
    pattern = "*",
    callback = function()
      loaded_dirs = {}
    end
  })
end

-- 手动重新加载当前目录片段的命令
local function setup_commands()
  vim.api.nvim_create_user_command("ReloadDirSnippets", function()
    local current_dir = get_current_file_dir()
    if current_dir then
      loaded_dirs[current_dir] = nil -- 清除缓存
      load_current_dir_snippets()    -- 重新加载
    end
  end, {})
end

-- 默认片段：当目录中没有自定义片段时使用
local function load_default_snippets()
  -- 通用片段
  ls.add_snippets("all", {
    s("todo", { t("-- TODO: "), i(1) }),
    s("fixme", { t("-- FIXME: "), i(1) }),
    s("date", {
      f(function() return os.date("%Y-%m-%d") end)
    }),
    s("time", {
      f(function() return os.date("%H:%M:%S") end)
    }),
  })
end

function M.setup()
  -- 加载默认片段
  load_default_snippets()

  -- 设置自动命令
  setup_autocmds()

  -- 设置命令
  setup_commands()

  -- vim.notify("动态片段加载已启用")
end

-- 在 snippets/init.lua 的 M.setup() 函数后添加
M.list_available_snippets = function()
  local filetype = vim.bo.filetype
  local current_dir = get_current_file_dir()

  print("当前文件类型: " .. filetype)
  print("当前目录: " .. (current_dir or "N/A"))

  local available_files = {}
  if current_dir then
    local patterns = {
      current_dir .. "/snippets/" .. filetype .. ".lua",
      current_dir .. "/.snippets/" .. filetype .. ".lua",
      current_dir .. "/" .. filetype .. "_snippets.lua",
    }

    for _, pattern in ipairs(patterns) do
      if vim.fn.filereadable(pattern) == 1 then
        table.insert(available_files, pattern)
      end
    end
  end

  if #available_files > 0 then
    print("找到的片段文件:")
    for _, file in ipairs(available_files) do
      print("  - " .. file)
    end
  else
    print("未找到当前目录的片段文件")
  end
end

-- 添加检查命令
vim.api.nvim_create_user_command("CheckSnippets", function()
  M.list_available_snippets()
end, {})

return M
