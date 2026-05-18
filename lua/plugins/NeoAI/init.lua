vim.pack.add({
  -- markdown渲染
  gh("kiran94/edit-markdown-table.nvim"),
  gh("MeanderingProgrammer/render-markdown.nvim"),
})

-- 加载本地插件 NeoAI（通过符号链接到 packpath）
vim.cmd("packadd NeoAI")

local godot_tools = require("plugins.NeoAI.tools.godot_tools")

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    require("NeoAI").setup({
      session = {
        auto_naming = false,
      },
      ai = {
        scenarios = {
          chat = {},
        },
      },
      tools = {
        external = godot_tools.get_tools(),
      },
    })
  end,
})
