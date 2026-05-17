-- 加载本地插件 NeoAI（通过符号链接到 packpath）
vim.cmd("packadd NeoAI")

vim.pack.add({
  -- markdown渲染
  gh("kiran94/edit-markdown-table.nvim"),
  gh("MeanderingProgrammer/render-markdown.nvim"),
})

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    require("NeoAI").setup({
      session = {
        auto_naming = false, -- 关闭自动命名
      },
      ai = {
        scenarios = {
          chat = {
            -- model_name = "deepseek-v4-pro",
          },
        },
      },
    })
  end,
})
