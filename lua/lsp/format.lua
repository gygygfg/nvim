-- ~/.config/nvim/lua/lsp/format.lua
-- 统一的格式化配置（conform.nvim）——全项目唯一的 conform.setup 调用

local config = require("lsp.config")

local M = {}

function M.setup()
  local ok, conform = pcall(require, "conform")
  if not ok then
    return
  end

  conform.setup({
    formatters_by_ft = config.formatters_by_ft,
    formatters = config.formatter_args,

    -- 保存时格式化（内置缓冲有效性检查，避免 "Invalid buffer id"）
    format_on_save = function(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
        return nil
      end
      local buftype = vim.bo[bufnr].buftype
      if buftype ~= "" and buftype ~= "acwrite" then
        return nil
      end
      if vim.bo[bufnr].filetype == "" then
        return nil
      end
      return { timeout_ms = 1000, lsp_format = "fallback" }
    end,

    log_level = vim.log.levels.WARN,
  })

  -- 手动格式化快捷键（唯一的格式化入口）
  vim.keymap.set({ "n", "v" }, "<leader>f", function()
    conform.format({ async = true, lsp_format = "fallback" })
  end, { noremap = true, silent = true, desc = "格式化文档" })
end

return M
