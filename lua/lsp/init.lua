-- lua/lsp/init.lua
-- LSP 全局配置 - 设置通用功能和按键映射

local lsp = vim.lsp

-- 1. 悬浮窗口样式
local hover_opts = {
  border = "rounded",
  max_width = 80,
  focusable = false,
}

-- 2. 通用按键映射

-- 文档和帮助
vim.keymap.set('n', 'K', function()
  lsp.buf.hover(hover_opts)
end, { desc = 'LSP: 悬浮文档' })

vim.keymap.set('n', '<C-k>', function()
  lsp.buf.signature_help()
end, { desc = 'LSP: 参数提示' })

-- 导航
vim.keymap.set('n', 'gd', lsp.buf.definition, { desc = 'LSP: 跳转到定义' })
vim.keymap.set('n', 'gD', lsp.buf.declaration, { desc = 'LSP: 跳转到声明' })
vim.keymap.set('n', 'gi', lsp.buf.implementation, { desc = 'LSP: 跳转到实现' })
vim.keymap.set('n', 'gr', lsp.buf.references, { desc = 'LSP: 查找引用' })
vim.keymap.set('n', '<leader>rn', lsp.buf.rename, { desc = 'LSP: 重命名符号' })

-- 代码操作
vim.keymap.set('n', '<leader>ca', lsp.buf.code_action, { desc = 'LSP: 代码操作' })
vim.keymap.set('n', '<leader>cf', function()
  vim.lsp.buf.format({ async = true })
end, { desc = 'LSP: 格式化代码' })

-- 工作区
vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, { desc = 'LSP: 添加工作区' })
vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, { desc = 'LSP: 移除工作区' })
vim.keymap.set('n', '<leader>wl', function()
  print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, { desc = 'LSP: 列出工作区' })

-- 3. LSP 语义高亮 (Neovim 0.12+)
if lsp.semantic_tokens then
  lsp.semantic_tokens.enable(true)
end

-- 4. 诊断配置
vim.diagnostic.config({
  virtual_text = {
    prefix = '●',
    spacing = 2,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = 'rounded',
    source = true,
  },
})

-- 诊断导航快捷键
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'LSP: 上一个诊断' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'LSP: 下一个诊断' })
vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist, { desc = 'LSP: 诊断列表' })

-- 5. LSP 进度显示 (fidget.nvim)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_attach_config", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      -- 启用补全
      if client:supports_method('textDocument/completion') then
        vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
      end
    end
  end,
})

-- 6. 用户命令
vim.api.nvim_create_user_command("LspInfo", function()
  vim.cmd("LspInfo")
end, { desc = "显示 LSP 信息" })

vim.notify("✅ LSP 全局配置已加载", vim.log.levels.INFO)

return {}
