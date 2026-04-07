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

vim.api.nvim_create_user_command("NvimTreeToggle", function()
  -- 文件浏览器 - 按需加载
  require('plugins.nvim_tree').toggle()
end, { desc = "切换文件浏览器" })

vim.api.nvim_create_user_command("TelescopeFind", function()
  -- Telescope - 按需加载
  require('plugins.telescope').setup()
  require('telescope.builtin').find_files()
end, { desc = "查找文件" })

-- 缩进2格的文件类型
autocmd("FileType", {
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

-- 缩进4格的文件类型
autocmd("FileType", {
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

-- 特殊文件类型设置
autocmd("FileType", {
  pattern = { "make" },
  callback = function()
    vim.opt_local.noexpandtab = true -- makefile 必须使用制表符
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
  group = mygroup
})

-- 保存时自动格式化
autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local filetype = vim.bo.filetype
    local sensitive_filetypes = { "yaml", "python", "yml", "dockerfile" }
    local is_sensitive = false
    for _, ft in ipairs(sensitive_filetypes) do
      if filetype == ft then
        is_sensitive = true
        break
      end
    end

    -- 检查是否有可用的LSP格式化功能
    local function has_lsp_formatting()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      for _, client in ipairs(clients) do
        if client.supports_method("textDocument/formatting") then
          return true
        end
      end
      return false
    end

    -- LSP格式化
    local function formatWithLSP()
      local has_formatting = has_lsp_formatting()
      if has_formatting then
        local save_cursor = vim.fn.getpos(".")
        vim.lsp.buf.format({ async = false })
        vim.fn.setpos(".", save_cursor)
        return true
      end
      return false
    end

    -- 优先使用LSP格式化
    local lsp_success = formatWithLSP()
    if not lsp_success and not is_sensitive then
      local save_cursor = vim.fn.getpos(".")
      vim.cmd("silent! normal! gg=G")
      vim.fn.setpos(".", save_cursor)
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
