vim.pack.add({
  -- markdown渲染
  gh("kiran94/edit-markdown-table.nvim"),
  gh("MeanderingProgrammer/render-markdown.nvim"),
})

-- 加载 NeoAI：优先本地开发目录 ~/code/NeoAI，否则从 GitHub 安装。
-- 命令（NeoAIOpen/Chat/Tree/Close/...）与全局快捷键（<leader>aa/ac/at/aq）
-- 均由插件 setup() 内联注册，这里只需配置。
local local_neoai = vim.fn.expand("~/code/NeoAI")
if vim.fn.filereadable(local_neoai .. "/lua/NeoAI/init.lua") == 1 then
  -- 本地存在：挂到 runtimepath 最前，require("NeoAI") 直接命中源码（实时生效）。
  vim.opt.rtp:prepend(local_neoai)
  -- 双保险：移除 GitHub 安装的旧副本（pack/*/opt/NeoAI），避免其抢先被 require
  -- 而加载到过期代码（曾导致本地改动不生效）。
  local stale = vim.fn.glob(vim.fn.stdpath("data") .. "/site/pack/*/opt/NeoAI", false, true)
  for _, p in ipairs(stale) do
    pcall(function() vim.opt.rtp:remove(p) end)
  end
else
  -- 本地不存在：从 GitHub 安装并 packadd
  vim.pack.add({ gh("gygygfg/NeoAI") })
  vim.cmd("packadd NeoAI")
end

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
      plan = { provider = "deepseek", model = "deepseek-v4-pro" },
      auto = { provider = "deepseek", model = "deepseek-flash" },
    },
  },
  tools = {
    external = godot_tools.get_tools(),
    -- 本机（Android/Termux）无 bwrap，且内核拒绝 unprivileged user namespace
    -- （`unshare: Operation not permitted`），故没有任何可用隔离后端。显式允许「直跑」：
    -- 命令直接在宿主执行（无沙箱隔离、写入直接落盘），并保留告警/审计。
    -- ⚠ 若更换到支持 bwrap/userns 的环境，请移除本项以恢复沙箱保护。
    sandbox = {
      allow_unisolated = true,
    },
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
