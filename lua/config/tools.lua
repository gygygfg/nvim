-- 工具和工具类插件配置

vim.pack.add({
  -- which-key.nvim - 按键提示
  { src = "https://github.com/folke/which-key.nvim" },
  -- noice.nvim - 通知系统
  { src = "https://github.com/folke/noice.nvim" },
  -- nui.nvim - UI 组件库（noice 依赖）
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  -- nvim-notify - 通知系统（noice 依赖）
  { src = "https://github.com/rcarriga/nvim-notify" },
  -- codecompanion.nvim - AI 代码助手
  { src = "https://github.com/olimorris/codecompanion.nvim" },
  -- mcphub.nvim - MCP Hub 集成
  { src = "https://github.com/ravitemer/mcphub.nvim" },
})

vim.api.nvim_create_autocmd('VimEnter', {
	    callback = function()
require("which-key").setup({
-- 配置 which-key
  plugins = {
    spelling = {
      enabled = true,
      suggestions = 20,
    },
  },
  window = {
    border = "single",
    position = "bottom",
    margin = { 1, 0, 1, 0 },
    padding = { 2, 2, 2, 2 },
  },
})

require("noice").setup({
-- 配置 noice
  lsp = {
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true,
    },
  },
  presets = {
    bottom_search = true,
    command_palette = true,
    long_message_to_split = true,
    inc_rename = false,
    lsp_doc_border = false,
  },
})

require("notify").setup({
-- 配置 nvim-notify
  timeout = 3000,
  max_height = function()
    return math.floor(vim.o.lines * 0.75)
  end,
  max_width = function()
    return math.floor(vim.o.columns * 0.75)
  end,
})

-- 设置 vim.notify 使用 nvim-notify
vim.notify = require("notify")
end
})
