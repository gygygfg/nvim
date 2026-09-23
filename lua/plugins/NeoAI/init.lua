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
    default_model = "deepseek-flash",
    -- 按模式（CHAT / PLAN / AUTO）分别配置 provider/model；
    -- 未写的 temperature/max_tokens/stream 沿用默认值。
    modes = {
      chat = { provider = "deepseek", model = "deepseek-flash" },
      plan = { provider = "deepseek", model = "deepseek-flash" },
      auto = { provider = "deepseek", model = "deepseek-flash" },
    },
  },
  tools = {
    external = godot_tools.get_tools(),
    -- 启用网页抓取工具：把动态网页（React/Vue/SPA）在无头浏览器渲染后转成 Markdown。
    -- ⚠️ 启用会自动安装 Node 依赖（node/npm 需已安装）；详见 NeoAI 默认配置注释。
    web_fetch = {
      enabled = true,
      -- 受限网络：浏览器内核走 npmmirror 镜像，并绕开本机损坏的 127.0.0.1:7890 代理
      npm_registry = "https://registry.npmmirror.com/",
      playwright_download_host = "https://registry.npmmirror.com/-/binary/playwright",
      ignore_system_proxy = true,
    },
  },
})
