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
    require("plugins.theme")
  end,
})

vim.api.nvim_create_user_command("TelescopeFind", function()
  -- Telescope - 按需加载
  require("plugins.telescope").setup()
  require("telescope.builtin").find_files()
end, { desc = "查找文件" })

autocmd("FileType", {
  -- 缩进2格的文件类型
  pattern = {
    "lua",
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "json",
    "css",
    "html",
    "xml",
    "yaml",
    "markdown",
    "sh",
    "bash",
    "zsh",
    "php",
    "ruby",
    "vim",
    "terraform",
    "hcl",
    "dockerfile",
    "yaml.docker-compose",
  },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
  group = mygroup,
})

autocmd("FileType", {
  -- 缩进4格的文件类型
  pattern = {
    "python",
    "java",
    "c",
    "cpp",
    "go",
    "rust",
    "swift",
    "kotlin",
    "scala",
    "cs",
    "dart",
    "perl",
    "fortran",
  },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
  group = mygroup,
})

autocmd("FileType", {
  -- 特殊文件类型设置
  pattern = { "make" },
  callback = function()
    vim.opt_local.noexpandtab = true -- makefile 必须使用制表符
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
  group = mygroup,
})

-- 说明：保存时格式化由 conform.nvim（lua/lsp/format.lua）统一负责，
-- 诊断显示由 lua/lsp/init.lua 中的 vim.diagnostic.config 统一配置。
