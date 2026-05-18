-- lua/plugins/godot.lua
-- Godot 引擎开发插件配置
-- 在打开 Godot 项目时自动加载并配置插件

vim.pack.add({
  gh("Mathijs-Bakker/godotdev.nvim"),
  gh("dpowling/godot-lsp.nvim"),
})

-- 局部变量，标记 godotdev 是否已加载
local godotdev_loaded = false

-- 将 gdscript 注册到主 LSP 系统，使其不被跳过
-- godotdev.nvim 使用 vim.lsp.config["gdscript"] + vim.lsp.enable("gdscript") 启动 LSP，
-- 服务名称为 "godot_editor"（见 godotdev/lsp.lua）
-- 主 LSP 系统使用白名单(filetype_mappings)，gdscript 不在其中时会将缓冲区标记为
-- lsp_started=true 并跳过，导致 LSP 按键映射和格式化等功能无法应用。
local lsp_module_ok, lsp_module = pcall(require, "lsp")
if lsp_module_ok then
  -- 注册 gdscript 相关文件类型到 LSP 系统
  lsp_module.filetype_mappings["gdscript"] = { "godot_editor" }
  lsp_module.filetype_mappings["gdresource"] = { "godot_editor" }
  lsp_module.filetype_mappings["gdshader"] = { "godot_editor" }

  -- 添加 GDScript 格式化器
  lsp_module.formatters_by_ft["gdscript"] = { "gdscript-formatter" }
  lsp_module.formatters_by_ft["gdresource"] = { "gdscript-formatter" }
  lsp_module.formatters_by_ft["gdshader"] = { "gdscript-formatter" }
end

-- 检测是否是 Godot 项目
local function is_godot_project()
  local root = vim.fs.root(0, { "project.godot" })
  return root ~= nil
end

-- 清除 gdscript 缓冲区的 lsp_started 标记，让主 LSP 系统可以正确附加
-- 主 LSP 系统（lsp/init.lua）使用白名单机制，当 `start_lsp_for_filetype` 发现文件类型
-- 不在 `filetype_mappings` 中时，会设置 `vim.b[bufnr].lsp_started = true` 并跳过。
-- 由于 gdscript 已被我们注册到 filetype_mappings，该标记不会由 LSP 系统设置，
-- 但为了兼容性，在 godotdev 加载后主动确保 gdscript 缓冲区的 LSP 正确附加。
local function ensure_gdscript_lsp_attached()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
      local ft = vim.bo[bufnr].filetype
      if ft == "gdscript" or ft == "gdresource" or ft == "gdshader" then
        -- 清除标记，让 LSP 系统可以处理此缓冲区
        vim.b[bufnr].lsp_started = nil
        -- 检查是否已有 godot_editor 客户端
        local clients = vim.lsp.get_clients({ name = "godot_editor", bufnr = bufnr })
        if #clients == 0 then
          -- 尝试附加到已存在的 godot_editor 客户端
          local all_clients = vim.lsp.get_clients({ name = "godot_editor" })
          for _, client in ipairs(all_clients) do
            if not vim.lsp.buf_is_attached(bufnr, client.id) then
              vim.lsp.buf_attach_client(bufnr, client.id)
              break
            end
          end
        end
      end
    end
  end
end

-- 检查端口是否被占用
local function is_port_in_use(port)
  local ok, result = pcall(vim.fn.system, {
    "ss",
    "-tlnp",
    "sport",
    "= :" .. port,
  })
  if not ok then
    -- 回退到 /proc/net/tcp 检查
    local f = io.open("/proc/net/tcp", "r")
    if f then
      local content = f:read("*a")
      f:close()
      local hex_port = string.format(":%04X", port)
      return content:find(hex_port) ~= nil
    end
    return false
  end
  return result ~= "" and not result:match("LISTEN")
end

-- 获取 Godot 可执行文件路径
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



-- 后台启动 Godot LSP 服务（如果端口未被占用）
local godot_lsp_job_id = nil

local function start_godot_lsp_server()
  if godot_lsp_job_id and vim.fn.jobpid(godot_lsp_job_id) > 0 then
    return true
  end

  if is_port_in_use(6005) then
    vim.notify("Godot LSP 端口 6005 已被占用，跳过启动后台服务", vim.log.levels.INFO)
    return true
  end

  local godot_bin = get_godot_binary()
  if not godot_bin then
    vim.notify("未找到 Godot 可执行文件，无法启动 LSP 服务", vim.log.levels.WARN)
    return false
  end

  local root = vim.fs.root(0, { "project.godot" })
  if not root then
    return false
  end

  local cmd = {
    godot_bin,
    "--editor",
    "--headless",
    "--no-window",
    "--lsp-port",
    "6005",
    "--path",
    root,
  }

  godot_lsp_job_id = vim.fn.jobstart(cmd, {
    cwd = root,
    detach = true,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            vim.notify("[godot-lsp] " .. line, vim.log.levels.DEBUG)
          end
        end
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 and code ~= -9 then
        vim.notify("Godot LSP 服务异常退出 (code=" .. code .. ")", vim.log.levels.WARN)
      end
      godot_lsp_job_id = nil
    end,
  })

  if godot_lsp_job_id <= 0 then
    vim.notify("启动 Godot LSP 服务失败", vim.log.levels.ERROR)
    godot_lsp_job_id = nil
    return false
  end

  vim.defer_fn(function()
    if not is_port_in_use(6005) then
      vim.notify("Godot LSP 服务可能未完全启动，请检查", vim.log.levels.WARN)
    end
  end, 2000)

  return true
end

-- 停止 Godot LSP 后台服务
local function stop_godot_lsp_server()
  if godot_lsp_job_id then
    pcall(vim.fn.jobstop, godot_lsp_job_id)
    godot_lsp_job_id = nil
  end
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
    auto_start = false,
    debug = false,
    silent = true,
  })
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
    editor_host = "127.0.0.1",
    editor_port = 6005,
    debug_port = 6006,
    autostart_editor_server = false,
    treesitter = {
      auto_setup = true,
      ensure_installed = { "gdscript" },
    },
    formatter = "gdscript-formatter",
    inline_hints = {
      enabled = false,
    },
    run = {
      console = {
        enabled = false,
        renderer = "buffer",
        buffer = {
          position = "bottom",
          size = 0.3,
        },
      },
    },
    scene_tree = {
      buffer = {
        position = "left",
        size = 0.35,
      },
      icons = "nerdfont",
    },
    docs = {
      renderer = "float",
      version = "stable",
      language = "en",
    },
  })

  godotdev_loaded = true

  ensure_gdscript_lsp_attached()

  -- 启动 Godot LSP 后台服务并配置客户端
  start_godot_lsp_server()
  setup_godot_lsp()

  vim.notify("🚀 Godot 开发工具已加载", vim.log.levels.INFO)
end

-- 从 export_presets.cfg 中解析所有可用的导出预设名
local function get_export_presets(root)
  local presets_file = root .. "/export_presets.cfg"
  local f = io.open(presets_file, "r")
  if not f then
    return {}
  end
  local content = f:read("*a")
  f:close()

  local presets = {}
  for name in content:gmatch('name%s*=%s*"([^"]+)"') do
    table.insert(presets, name)
  end
  return presets
end



-- 保存当前后台 job id，用于清理
local web_jobs = {}

-- 自动创建默认 Web 导出预设
local function create_web_export_preset(root)
  local presets_file = root .. "/export_presets.cfg"
  if vim.fn.filereadable(presets_file) == 1 then
    return true
  end

  local content = [[
[preset.0]

name="Web"
platform="Web"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/web/index.html"
encryption_include_filters=""
encryption_exclude_filters=""

[preset.0.options]

custom_template/debug=""
custom_template/release=""
variant/extensions_support=false
vram_compression/use_s3tc=true
vram_compression/use_etc=false
vram_compression/use_etc2=false
vram_compression/use_bptc=true
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=0
progressive_web_app/enabled=false
progressive_web_app/offline_page=""
progressive_web_app/display=0
progressive_web_app/orientation=0
progressive_web_app/icon_144x144=""
progressive_web_app/icon_180x180=""
progressive_web_app/icon_512x512=""
progressive_web_app/background_color=Color(0, 0, 0, 1)
]]

  local f = io.open(presets_file, "w")
  if not f then
    return false
  end
  f:write(content)
  f:close()
  return true
end

local function cleanup_web_jobs()
  for _, job_id in ipairs(web_jobs) do
    local ok = pcall(vim.fn.jobstop, job_id)
    if not ok then
      pcall(vim.fn.jobstop, job_id)
    end
  end
  web_jobs = {}
end

-- 导出 Godot 项目为 HTML5 并启动本地服务
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

  local presets_file = root .. "/export_presets.cfg"
  local has_presets = vim.fn.filereadable(presets_file) == 1
  if not has_presets then
    vim.notify("未找到 export_presets.cfg，正在自动创建默认 Web 导出预设...", vim.log.levels.INFO)
    local ok = create_web_export_preset(root)
    if not ok then
      vim.notify("自动创建导出预设失败", vim.log.levels.ERROR)
      return
    end
    has_presets = vim.fn.filereadable(presets_file) == 1
    if not has_presets then
      vim.notify("创建导出预设失败", vim.log.levels.ERROR)
      return
    end
    vim.notify("✅ 已自动创建 export_presets.cfg", vim.log.levels.INFO)
  end

  local available_presets = get_export_presets(root)
  if #available_presets == 0 then
    vim.notify(
      "export_presets.cfg 中未找到任何导出预设，正在自动创建 Web 预设...",
      vim.log.levels.WARN
    )
    local backup = presets_file .. ".bak"
    os.rename(presets_file, backup)
    local ok = create_web_export_preset(root)
    if not ok then
      os.rename(backup, presets_file)
      vim.notify("自动创建 Web 预设失败", vim.log.levels.ERROR)
      return
    end
    os.remove(backup)
    available_presets = get_export_presets(root)
    if #available_presets == 0 then
      vim.notify("创建 Web 预设后仍无可用预设", vim.log.levels.ERROR)
      return
    end
    vim.notify("✅ 已自动创建 Web 导出预设", vim.log.levels.INFO)
  end

  local export_preset
  if opts.args and opts.args ~= "" then
    export_preset = opts.args
  else
    for _, p in ipairs(available_presets) do
      if p:lower():find("web") or p:lower():find("html") then
        export_preset = p
        break
      end
    end
    export_preset = export_preset or available_presets[1]
  end

  cleanup_web_jobs()

  local export_path = root .. "/build/web/index.html"
  local server_port = 8080

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "godot://export-web")
  vim.api.nvim_buf_set_option(buf, "buftype", "acwrite")
  vim.api.nvim_buf_set_option(buf, "filetype", "godot-export")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

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

  local function strip_ansi_codes(text)
    return text:gsub("\027%[[%d;]*%a", "")
  end

  local function append_output(text)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    local clean_text = strip_ansi_codes(text)
    local lines = vim.split(clean_text, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
  end

  local cmd = { godot_bin, "--headless", "--export-debug", export_preset, export_path }

  append_output("🎮 正在导出 HTML5 项目...")
  append_output("")
  append_output(string.format("📂 项目路径: %s", root))
  append_output(string.format("🔧 导出预设: %s", export_preset))
  append_output(string.format("📦 导出路径: %s", export_path))
  append_output(string.format("🏗️  执行命令: %s", table.concat(cmd, " ")))
  append_output("")

  local export_job = vim.fn.jobstart(cmd, {
    cwd = root,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            append_output(line)
          end
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            append_output("[stderr] " .. line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        append_output("")
        append_output("❌ Godot 导出失败，退出码: " .. exit_code)
        append_output("")
        append_output("💡 可能的原因：")
        append_output("  1. 导出预设配置有误（删除 export_presets.cfg 后重试）")
        append_output("  2. build/web/ 目录权限问题")
        append_output("  3. Godot 引擎问题")
        return
      end

      append_output("")
      append_output("✅ 导出成功！启动 HTTP 服务...")

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
  desc = "导出 Godot 项目为 HTML5 并启动本地 HTTP 服务",
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

-- 退出时清理 Godot LSP 后台服务
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    stop_godot_lsp_server()
  end,
})
