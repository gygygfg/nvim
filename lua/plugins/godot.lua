-- lua/plugins/godot.lua
-- Godot 引擎开发插件配置
-- 在打开 Godot 项目时自动加载并配置插件

vim.pack.add({
  gh("Mathijs-Bakker/godotdev.nvim"),
  gh("dpowling/godot-lsp.nvim"),
})

-- 局部变量，标记 godotdev 是否已加载
local godotdev_loaded = false

-- 检测是否是 Godot 项目
local function is_godot_project()
  local root = vim.fs.root(0, { "project.godot" })
  return root ~= nil
end

-- 加载并配置 godotdev.nvim
local function setup_godotdev()
  if godotdev_loaded then
    return
  end

  local ok, godotdev = pcall(require, "godotdev")
  if not ok then
    vim.notify("godotdev.nvim 未找到，请检查插件安装", vim.log.levels.WARN)
    return
  end

  godotdev.setup({
    -- 编辑器服务器配置
    editor_host = "127.0.0.1",
    editor_port = 6005,
    debug_port = 6006,
    autostart_editor_server = false, -- 手动启动，避免自动连接

    -- Tree-sitter 配置
    treesitter = {
      auto_setup = true,
      ensure_installed = { "gdscript" },
    },

    -- 格式化器
    formatter = "gdscript-formatter",

    -- 行内提示
    inline_hints = {
      enabled = false,
    },

    -- 运行控制台
    run = {
      console = {
        enabled = false, -- 设为 true 可在 Neovim 中捕获运行输出
        renderer = "buffer",
        buffer = {
          position = "bottom",
          size = 0.3,
        },
      },
    },

    -- 场景树
    scene_tree = {
      buffer = {
        position = "left",
        size = 0.35,
      },
      icons = "nerdfont",
    },

    -- 文档
    docs = {
      renderer = "float",
      version = "stable",
      language = "en",
    },
  })

  godotdev_loaded = true
  vim.notify("🚀 Godot 开发工具已加载", vim.log.levels.INFO)
end

-- 加载并配置 godot-lsp.nvim（独立 LSP 客户端）
local function setup_godot_lsp()
  local ok, godot_lsp = pcall(require, "godot-lsp")
  if not ok then
    return
  end

  godot_lsp.setup({
    port = 6005,
    fallback_port = 6006,
    auto_start = false, -- godotdev 已接管 LSP，设为 false 避免冲突
    debug = false,
    silent = true,
  })
end

-- 导出 Godot 项目为 HTML5 并启动本地服务（快速调试用）
local function get_godot_binary()
  local candidates = {
    "godot",
    "godot4",
    "Godot",
    "Godot_v4.3-stable_x11.64",
    vim.fn.expand("~/Godot/Godot_v4.3-stable_x11.64"),
  }
  for _, bin in ipairs(candidates) do
    if vim.fn.executable(bin) == 1 then
      return bin
    end
  end
  return nil
end

-- 保存当前后台 job id，用于清理
local web_jobs = {}

local function cleanup_web_jobs()
  for _, job_id in ipairs(web_jobs) do
    vim.fn.jobstop(job_id)
  end
  web_jobs = {}
end

vim.api.nvim_create_user_command("GodotExportWeb", function(opts)
  local root = vim.fs.root(0, { "project.godot", "export_presets.cfg" })
  if not root then
    vim.notify("当前不在 Godot 项目中，未找到 project.godot", vim.log.levels.ERROR)
    return
  end

  local godot_bin = get_godot_binary()
  if not godot_bin then
    vim.notify("未找到 Godot 可执行文件，请确认已安装", vim.log.levels.ERROR)
    return
  end

  -- 先清理之前的 job
  cleanup_web_jobs()

  local export_mode = opts.args or "web"
  local export_path = root .. "/build/web/index.html"
  local server_port = 8080

  -- 创建终端窗口显示日志
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "godot://export-web")
  vim.api.nvim_buf_set_option(buf, "buftype", "acwrite")
  vim.api.nvim_buf_set_option(buf, "filetype", "godot-export")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- 窗口关闭时自动清理
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      cleanup_web_jobs()
    end,
  })

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.6),
    col = math.floor(vim.o.columns * 0.1),
    row = math.floor(vim.o.lines * 0.15),
    style = "minimal",
    border = "rounded",
    title = " Godot Export Web ",
    title_pos = "center",
  })
  vim.api.nvim_win_set_option(win, "winhl", "NormalFloat:NormalFloat,FloatBorder:FloatBorder")

  local function append_output(text)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    local lines = vim.split(text, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
  end

  append_output("🎮 正在导出 HTML5 项目...")
  append_output("")

  -- 导出 job
  local export_job = vim.fn.jobstart({ godot_bin, "--headless", "--export-debug", export_mode, export_path }, {
    cwd = root,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        append_output(table.concat(data, "\n"))
      end
    end,
    on_stderr = function(_, data)
      if data then
        append_output("[stderr] " .. table.concat(data, "\n"))
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        append_output("")
        append_output("❌ Godot 导出失败，退出码: " .. exit_code)
        return
      end

      append_output("")
      append_output("✅ 导出成功！启动 HTTP 服务...")

      -- HTTP 服务 job
      local server_job = vim.fn.jobstart({ "npx", "http-server", ".", "-p", tostring(server_port), "-c-1", "--cors" }, {
        cwd = root .. "/build/web",
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
          if data then
            append_output(table.concat(data, "\n"))
          end
        end,
        on_stderr = function(_, data)
          if data then
            append_output("[stderr] " .. table.concat(data, "\n"))
          end
        end,
        on_exit = function(_, code)
          append_output("")
          append_output("🛑 HTTP 服务已退出 (code=" .. code .. ")")
        end,
      })
      table.insert(web_jobs, server_job)

      append_output("")
      append_output(string.format("🌐 http://localhost:%d", server_port))
      append_output("")
      append_output("💡 关闭此窗口可自动停止所有服务")
    end,
  })
  table.insert(web_jobs, export_job)
end, {
  nargs = "?",
  complete = "file",
  desc = "导出 Godot 项目为 HTML5 并在终端窗口查看日志",
})

-- 创建用户命令，手动加载 Godot 插件
vim.api.nvim_create_user_command("LoadGodot", function()
  setup_godotdev()
  vim.notify("Godot 插件已手动加载", vim.log.levels.INFO)
end, {})

-- 方案一：打开 Godot 相关文件时自动加载
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.gd", "*.godot", "project.godot", "*.tscn", "*.tres", "*.gdnlib", "*.gdns" },
  callback = function()
    if not godotdev_loaded and is_godot_project() then
      setup_godotdev()
    end
  end,
})

-- 方案二：进入 Godot 项目目录时自动加载
vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    if not godotdev_loaded and is_godot_project() then
      setup_godotdev()
    end
  end,
})

-- 方案三：启动时如果当前就在 Godot 项目中，自动加载
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if not godotdev_loaded and is_godot_project() then
      setup_godotdev()
    end
  end,
})

-- 按键映射（可选，取消注释启用）
-- vim.keymap.set("n", "<leader>gr", function()
--   require("godotdev.run").run_project()
-- end, { desc = "运行 Godot 项目" })
--
-- vim.keymap.set("n", "<leader>gs", function()
--   require("godotdev.scene_tree").toggle()
-- end, { desc = "切换 Godot 场景树" })
