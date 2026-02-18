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

-- Neovim 0.11.6 LSP API 兼容性补丁
local function patch_lsp_apis_for_0116()
  -- 检查是否是 Neovim 0.11.6
  local version = vim.version()
  if version.major == 0 and version.minor >= 11 then
    -- Neovim 0.11+ 已经有新的API，不需要补丁
    return
  end
  
  -- 对于旧版本，提供兼容性补丁
  if not vim.lsp.get_clients then
    vim.lsp.get_clients = function(filter)
      filter = filter or {}
      if type(filter) == "string" then
        filter = {}
      end
      return vim.lsp.get_active_clients(filter) or {}
    end
  end
  
  -- 确保 buf_get_clients 函数存在
  if not vim.lsp.buf_get_clients then
    vim.lsp.buf_get_clients = function(bufnr)
      bufnr = bufnr or vim.api.nvim_get_current_buf()
      return vim.lsp.get_clients({ bufnr = bufnr })
    end
  end
end

-- 应用补丁
patch_lsp_apis_for_0116()

-- 加载函数模块
require("nvim_venv").setup()
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
})
