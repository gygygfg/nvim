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
local pack_specs = {
  -- 安装软件包而不加载
  -- 主题相关
  gh("folke/tokyonight.nvim"),
  gh("nvim-tree/nvim-web-devicons"),
  -- 界面增强
  gh("nvim-lualine/lualine.nvim"),
  gh("akinsho/bufferline.nvim"),
  gh("folke/noice.nvim"),
  gh("rcarriga/nvim-notify"),
  -- 文件浏览
  gh("nvim-tree/nvim-tree.lua"),
  -- 编辑增强
  gh("nvim-treesitter/nvim-treesitter"),
  gh("windwp/nvim-autopairs"),
  gh("numToStr/Comment.nvim"),
  -- 模糊搜索
  gh("nvim-telescope/telescope.nvim"),
  gh("nvim-lua/plenary.nvim"),
  -- AI 辅助
  gh("olimorris/codecompanion.nvim"),
  gh("github/copilot.vim"),
  -- 工具类
  gh("nvim-lua/popup.nvim"),
}

local ok, err = pcall(vim.pack.add, pack_specs)
if not ok then
  vim.notify("vim.pack.add failed: " .. tostring(err), vim.log.levels.WARN)
end

-- 加载必需的插件（确保在配置之前可用）
vim.cmd.packadd("tokyonight.nvim")
vim.cmd.packadd("nvim-treesitter")
vim.cmd.packadd("nvim-web-devicons")
-- 3. 加载核心配置

-- 加载基础选项和按键映射
require("core.notify_config")
require("core.options")
require("core.keymaps")
require("core.autocommands")

-- 加载LSP配置
require("lsp").setup()

require("plugins-manager").setup({
  -- 4. 加载插件配置
  auto_load = true, -- 自动加载所有插件
  -- print_list = true -- 打印可用插件列表
})

-- 通知用户配置已加载
vim.notify("Neovim 配置加载完成", vim.log.levels.INFO)
