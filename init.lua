-- ~/.config/nvim/init.lua
-- Neovim 主入口文件 - 基于 vim.pack 插件管理器

-- 1. 基础设置

-- 获取配置目录并添加到 package.path
local config_dir = vim.fn.fnamemodify(vim.fn.expand("<sfile>"), ":p:h")
local lua_dir = config_dir .. "/lua"
package.path = package.path .. ";" .. lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua"

-- 确保插件目录存在
local function ensure_dir(path)
  vim.fn.mkdir(path, "p")
end
ensure_dir(vim.fn.stdpath("data") .. "/site/pack/core/opt")

-- 2. 插件声明 (使用 vim.pack.add)
-- 所有插件默认放置在 opt/ 目录，按需加载

-- 辅助函数：简化 GitHub 地址书写
_G.gh = function(x)
  return "https://github.com/" .. x
end

-- Wrap vim.pack.add to handle git HEAD errors
vim.pack.add({
  -- 安装软件包而不加载
  -- 主题相关
  gh("nvim-tree/nvim-web-devicons"),
  -- 界面增强
  gh("folke/noice.nvim"),
  gh("rcarriga/nvim-notify"),
  -- AI 辅助
  gh("github/copilot.vim"),
  -- 工具类
  gh("nvim-lua/popup.nvim"),
})

-- 3. 加载核心配置

-- 加载基础选项和按键映射
require("core.notify_config")
require("core.options")
require("core.keymaps")
require("core.autocommands")
-- 缩进折叠：折叠层级跟随 shiftwidth，缩进选项变化时自动重算（详见 lua/core/folding.lua）
require("core.folding").setup()

-- 加载自动拼写纠正模块
local spell_ok, spell = pcall(require, "core.spell")
if spell_ok then
  spell.setup({
    enabled = true,
    languages = { "en_us" },
    auto_correct_on_tab = true, -- 按 Tab 时自动纠正
    camel_case = true,
    max_suggestions = 5,

    -- 文件类型配置
    enable_for = { "markdown", "text", "gitcommit", "latex", "tex", "rst" },
    disable_for = { "lua", "python", "javascript", "typescript", "java", "cpp", "c", "go", "rust" },
  })
else
  -- 如果拼写模块加载失败，使用基本设置
  vim.opt.spelllang = "en_us"
  vim.opt.spellsuggest = "best"
  vim.opt.spelloptions = "camel"
end

-- 加载LSP配置
require("lsp").setup()

-- 加载虚拟环境模块
require("core.python_venv").setup()
require("core.nvm_venv").setup()

require("plugins-manager").setup({
  -- 4. 加载插件配置
  auto_load = true, -- 自动加载所有插件
  -- print_list = true -- 打印可用插件列表
})

-- 插件加载完成后再刷新一次 LSP：此刻 cmp_nvim_lsp 已可用，
-- 用它重新烘焙 capabilities（require("lsp").setup() 时 cmp 尚未加载）。
pcall(function()
  require("lsp").refresh()
end)

-- 通知用户配置已加载
vim.notify("Neovim 配置加载完成", vim.log.levels.INFO)
