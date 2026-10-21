-- ~/.config/nvim/lua/lsp/format.lua
-- 统一的格式化配置（conform.nvim）——全项目唯一的 conform.setup 调用

local config = require("lsp.config")
local format_guard = require("core.format_guard")

local M = {}

--- 根据缓冲区 filetype 选择 conform 的 lsp_format 策略。
--- java 没有可用的 CLI 格式化器（google-java-format 在 Termux 不可用），
--- 且 formatters_by_ft["*"] = { "codespell" } 使 java 恒存在 CLI formatter，
--- 故不能用 "fallback"（那不会触发 LSP），必须用 "first" 走 jdtls 内置格式化。
---@param bufnr integer|nil
---@return string
local function lsp_format_for(bufnr)
  local ft = vim.bo[bufnr or 0].filetype
  return ft == "java" and "first" or "fallback"
end

function M.setup()
  local ok, conform = pcall(require, "conform")
  if not ok then
    return
  end

  conform.setup({
    formatters_by_ft = config.formatters_by_ft,
    formatters = config.formatter_args,

    -- 保存时格式化（用统一守卫拦截 nomodifiable / 特殊缓冲区）
    format_on_save = function(bufnr)
      if not format_guard.is_formattable(bufnr) then
        return false
      end
      return { timeout_ms = 1000, lsp_format = lsp_format_for(bufnr) }
    end,

    log_level = vim.log.levels.WARN,
  })

  -- 手动格式化快捷键（唯一的格式化入口）
  vim.keymap.set({ "n", "v" }, "<leader>f", function()
    if not format_guard.is_formattable() then
      vim.notify("[LSP] 当前缓冲区不可格式化（权限受限或特殊缓冲区）", vim.log.levels.WARN)
      return
    end
    conform.format({ async = true, lsp_format = lsp_format_for(0) })
  end, { noremap = true, silent = true, desc = "格式化文档" })

  -- 查看当前文件类型的格式化器
  vim.keymap.set("n", "<leader>F", function()
    local formatters = config.formatters_by_ft[vim.bo.filetype] or {}
    vim.notify(
      "文件类型: " .. vim.bo.filetype .. "\n格式化器: " .. (#formatters > 0 and table.concat(formatters, ", ") or "无"),
      vim.log.levels.INFO
    )
  end, { noremap = true, silent = true, desc = "查看格式化器" })
end

return M
