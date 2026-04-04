-- 使用 load 包装函数收集包信息
load.addPack({
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

load.nvim_create_autocmd('VimEnter', {
  -- 使用 load 包装函数注册 autocmd
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
      },
    })
  end
})
