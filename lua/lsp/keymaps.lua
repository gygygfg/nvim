-- ~/.config/nvim/lua/lsp/keymaps.lua
-- LSP 键位：缓冲区级映射随 LspAttach 自动挂载；诊断跳转全局挂载

local M = {}

local function buf_map(bufnr, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true, desc = desc })
end

-- 缓冲区级 LSP 键位
local function on_attach(_, bufnr)
  buf_map(bufnr, "n", "gd", vim.lsp.buf.definition, "跳转到定义")
  buf_map(bufnr, "n", "gK", vim.lsp.buf.hover, "悬停文档")
  buf_map(bufnr, "n", "gr", vim.lsp.buf.references, "查看引用")
  buf_map(bufnr, "n", "gi", vim.lsp.buf.implementation, "查看实现")
  buf_map(bufnr, "n", "gt", vim.lsp.buf.type_definition, "跳转到类型定义")
  buf_map(bufnr, "i", "<C-k>", vim.lsp.buf.signature_help, "签名帮助")
  buf_map(bufnr, { "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "代码操作")
  buf_map(bufnr, "n", "<leader>rn", vim.lsp.buf.rename, "重命名符号")

  -- 若服务器支持格式化，让 gq / 格式化运算符走 LSP
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client:supports_method("textDocument/formatting") then
      vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr(#{timeout_ms:1000})"
      break
    end
  end
end

-- 全局诊断键位（不依赖 LSP 客户端）
local function global_diagnostics()
  vim.keymap.set("n", "g[", function()
    vim.diagnostic.jump({ count = -1, severity_limit = vim.diagnostic.severity.WARN })
    vim.diagnostic.open_float()
  end, { noremap = true, silent = true, desc = "上一个诊断" })

  vim.keymap.set("n", "g]", function()
    vim.diagnostic.jump({ count = 1, severity_limit = vim.diagnostic.severity.WARN })
    vim.diagnostic.open_float()
  end, { noremap = true, silent = true, desc = "下一个诊断" })

  vim.keymap.set("n", "go", vim.diagnostic.open_float, { noremap = true, silent = true, desc = "显示诊断详情" })
  vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { noremap = true, silent = true, desc = "诊断到位置列表" })
end

function M.setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true }),
    callback = function(args)
      on_attach(nil, args.buf)
    end,
  })

  global_diagnostics()
end

return M
