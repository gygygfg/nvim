-- lua/core/autocommands.lua
-- 自动命令配置

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- 创建自动命令组
local mygroup = augroup("MyConfig", { clear = true })

-- 文件类型相关设置

vim.api.nvim_create_autocmd("UIEnter", {
  -- 主题配置 - 启动时加载
  once = true,
  callback = function()
    require('plugins.theme')
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  -- 状态栏和缓冲区 - 启动后加载
  once = true,
  callback = function()
    pcall(require, 'plugins.lualine')
    pcall(require, 'plugins.bufferline')
  end,
})

vim.api.nvim_create_user_command("TelescopeFind", function()
  -- Telescope - 按需加载
  require('plugins.telescope').setup()
  require('telescope.builtin').find_files()
end, { desc = "查找文件" })

autocmd("FileType", {
  -- 缩进2格的文件类型
  pattern = {
    "lua", "javascript", "typescript", "javascriptreact", "typescriptreact",
    "json", "css", "html", "xml", "yaml", "markdown", "sh", "bash", "zsh",
    "php", "ruby", "vim", "terraform", "hcl", "dockerfile", "yaml.docker-compose"
  },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
  group = mygroup
})

autocmd("FileType", {
  -- 缩进4格的文件类型
  pattern = {
    "python", "java", "c", "cpp", "go", "rust", "swift",
    "kotlin", "scala", "cs", "dart", "perl", "fortran"
  },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
  group = mygroup
})

autocmd("FileType", {
  -- 特殊文件类型设置
  pattern = { "make" },
  callback = function()
    vim.opt_local.noexpandtab = true -- makefile 必须使用制表符
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
  group = mygroup
})

autocmd("BufWritePre", {
  -- 保存时自动格式化（兼容 conform.nvim 和 LSP）
  pattern = "*",
  callback = function(args)
    local bufnr = args.buf
    local filetype = vim.bo[bufnr].filetype

    -- 敏感文件类型列表（不使用 indent 格式化）
    local sensitive_filetypes = { "yaml", "python", "yml", "dockerfile" }
    local is_sensitive = false
    for _, ft in ipairs(sensitive_filetypes) do
      if filetype == ft then
        is_sensitive = true
        break
      end
    end

    -- 1. 首先尝试使用 conform.nvim
    local conform_ok, conform = pcall(require, "conform")
    if conform_ok then
      local success = pcall(conform.format, {
        async = false,
        bufnr = bufnr,
        lsp_fallback = true, -- 如果 conform 没有格式化器，回退到 LSP
        timeout_ms = 1000,
      })

      if success then
        vim.notify('conform 格式化成功')
        return
      end
    end

    local function has_lsp_formatting()
      -- 2. 如果 conform.nvim 不可用或格式化失败，尝试 LSP
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      for _, client in ipairs(clients) do
        if client.supports_method("textDocument/formatting") then
          return true
        end
      end
      return false
    end

    local function format_with_lsp()
      local has_formatting = has_lsp_formatting()
      if has_formatting then
        local save_cursor = vim.fn.getpos(".")
        vim.lsp.buf.format({ async = false, bufnr = bufnr })
        vim.notify('使用 LSP 格式化')
        vim.fn.setpos(".", save_cursor)
        return true
      end
      return false
    end

    local lsp_success = format_with_lsp()

    -- 3. 如果 LSP 格式化失败，并且不是敏感文件类型，使用 indent 格式化
    if not lsp_success and not is_sensitive then
      local save_cursor = vim.fn.getpos(".")
      vim.cmd("silent! normal! gg=G")
      vim.notify('使用 gg=G 格式化')
      vim.fn.setpos(".", save_cursor)
    end
  end,
  group = mygroup
})

autocmd("FileType", {
  -- 添加一个自动命令来设置文件类型的格式化器
  pattern = "*",
  callback = function(args)
    local bufnr = args.buf
    local filetype = vim.bo[bufnr].filetype

    -- 检查是否有对应的格式化器配置
    local formatter_config_ok, formatters_by_ft = pcall(require, "lsp")
    if formatter_config_ok and formatters_by_ft and formatters_by_ft.formatters_by_ft then
      local formatters = formatters_by_ft.formatters_by_ft[filetype]
      if formatters then
        -- 可选：显示当前文件类型的可用格式化器
        vim.b[bufnr].conform_formatters = formatters
      end
    end
  end,
  group = mygroup
})

-- 诊断配置
vim.diagnostic.config({
  virtual_text = {
    enabled = false,
    prefix = "■"
  },
  float = {
    border = "none"
  }
})
