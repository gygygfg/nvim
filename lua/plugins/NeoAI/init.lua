vim.pack.add({
  -- markdown渲染
  gh("kiran94/edit-markdown-table.nvim"),
  gh("MeanderingProgrammer/render-markdown.nvim"),
})

-- 加载本地插件 NeoAI（通过符号链接到 packpath）。
-- 命令（NeoAIOpen/Chat/Tree/Close/...）与全局快捷键（<leader>aa/ac/at/aq）
-- 均由插件 setup() 内联注册，这里只需配置。
vim.cmd("packadd NeoAI")

local godot_tools = require("plugins.NeoAI.tools.godot_tools")

require("NeoAI").setup({
  session = {
    auto_naming = false,
  },
  ai = {
    -- 兜底模型（未配置的模式 / "auto" 解析时回退到 registry 默认）
    default_model = "deepseek-v4-flash-vision-exp",
    -- 按模式（CHAT / PLAN / AUTO）分别配置 provider/model；
    -- 未写的 temperature/max_tokens/stream 沿用默认值。
    modes = {
      chat = { provider = "deepseek", model = "deepseek-v4-flash-vision-exp" },
      plan = { provider = "deepseek", model = "deepseek-v4-flash-vision-exp" },
      auto = { provider = "deepseek", model = "deepseek-v4-flash-vision-exp" },
    },
  },
  tools = {
    external = godot_tools.get_tools(),
  },
})
