local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 加载 NVM 环境配置
require("nvm_init").setup()
require("python_venv").setup()

-- 加载函数模块
require("keymaps").main()
require("local_conf")

require("lazy").setup("plugins", {
  defaults = {
    lazy = true, -- 开启默认懒加载
    -- 其他全局默认配置...
  },
  git = {
    -- url_format = "https://xget.xi-xu.me/gh/%s.git",
  },
  -- rocks = {
  --   enabled = false,     -- 彻底禁用 luarocks，使用纯 Lua 插件
  -- }
})
