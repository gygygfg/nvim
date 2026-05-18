-- conform.nvim 格式化配置
-- 在格式化前检查缓冲区有效性，避免 "Invalid buffer id" 错误

local conform_ok, conform = pcall(require, "conform")
if not conform_ok then
  -- 如果 conform 未安装，尝试加载
  vim.cmd("packadd conform.nvim")
  local ok, mod = pcall(require, "conform")
  if not ok then
    return
  end
  conform = mod
end

conform.setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "isort", "black" },
    javascript = { "prettierd", "prettier" },
    typescript = { "prettierd", "prettier" },
    json = { "prettierd", "prettier" },
    yaml = { "prettierd", "prettier" },
    markdown = { "prettierd", "prettier" },
    go = { "gofumpt", "goimports" },
    rust = { "rustfmt" },
    c = { "clang-format" },
    cpp = { "clang-format" },
  },
  format_on_save = function(bufnr)
    -- 关键修复：在格式化前检查缓冲区是否有效
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return false
    end
    -- 检查缓冲区是否已加载
    if not vim.api.nvim_buf_is_loaded(bufnr) then
      return false
    end
    -- 只在非特殊缓冲区中格式化
    local buftype = vim.bo[bufnr].buftype
    if buftype ~= "" and buftype ~= "acwrite" then
      return false
    end
    return { lsp_format = "fallback", timeout_ms = 1000 }
  end,
  formatters = {
    -- 每个格式化器的配置
    prettier = {
      prepend_args = { "--print-width", "100" },
    },
  },
  -- 日志级别，设为 "warn" 减少干扰
  log_level = vim.log.levels.WARN,
})

vim.notify("conform.nvim 已配置（带缓冲区有效性检查）", vim.log.levels.INFO)
