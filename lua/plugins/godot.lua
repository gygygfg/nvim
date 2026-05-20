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

  -- 预注册 godot_editor 服务器配置到 _server_configs，
  -- 让主 LSP 系统在 start_server_with_config 时能直接使用。
  -- 注意：由于此时 godotdev 尚未 setup，vim.lsp.config["gdscript"] 可能为空，
  -- 实际注册延迟到 setup_godotdev() 中 godotdev.setup() 之后完成。
  -- 这里先确保 _server_configs 表存在。
  if not lsp_module._server_configs then
    lsp_module._server_configs = {}
  end
end

-- 检测是否是 Godot 项目
local function is_godot_project()
  local root = vim.fs.root(0, { "project.godot" })
  return root ~= nil
end

-- 清除 gdscript 缓冲区的 lsp_started 标记，让主 LSP 系统可以正确附加
-- 函数已增强：当找不到已存在的 godot_editor 客户端时，会通过主 LSP 系统的
-- start_lsp_for_filetype 重新触发完整的 LSP 启动流程（包括启动新客户端）。
-- 
local function ensure_gdscript_lsp_attached()
  local gdscript_bufs = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
      local ft = vim.bo[bufnr].filetype
      if ft == "gdscript" or ft == "gdresource" or ft == "gdshader" then
        table.insert(gdscript_bufs, bufnr)
      end
    end
  end

  if #gdscript_bufs == 0 then
    return
  end

  -- 检查是否有可用的 godot_editor 客户端
  local all_clients = vim.lsp.get_clients({ name = "godot_editor" })
  local has_working_client = false
  for _, client in ipairs(all_clients) do
    -- 简单检查客户端是否存活（有 rpc handle）
    if client.rpc and client.rpc.handle then
      has_working_client = true
      break
    end
  end

  if not has_working_client then
    -- 没有可用的客户端，清理所有残留的 failed/stopped 客户端
    for _, client in ipairs(all_clients) do
      if client.rpc and client.rpc.handle then
        -- 客户端存活但未在上方被标记为 working？实际上这里是清理所有
        -- 安全起见，只清理"没有 rpc handle"的
      else
        pcall(client.stop, client)
      end
    end

    -- 通过主 LSP 系统重新启动 LSP 客户端
    -- 使用 pcall 获取主 LSP 模块并调用 start_lsp_for_filetype
    local lsp_ok, lsp_mod = pcall(require, "lsp")
    if lsp_ok and lsp_mod.start_lsp_for_filetype then
      for _, bufnr in ipairs(gdscript_bufs) do
        if vim.api.nvim_buf_is_valid(bufnr) then
          local ft = vim.bo[bufnr].filetype
          -- 清除标记，让 LSP 系统可以重新处理此缓冲区
          vim.b[bufnr].lsp_started = nil
          -- 调用主 LSP 系统的启动函数（包含 start_server_with_config）
          lsp_mod.start_lsp_for_filetype(ft, bufnr)
        end
      end
      return
    end

    -- 回退：直接使用 Neovim 内置 LSP 启用
    if vim.lsp.config["gdscript"] and vim.lsp.config["gdscript"].cmd then
      vim.lsp.enable("gdscript")
      -- 给 autocmd 一个机会执行
      vim.schedule(function()
        for _, bufnr in ipairs(gdscript_bufs) do
          if vim.api.nvim_buf_is_valid(bufnr) then
            vim.b[bufnr].lsp_started = nil
          end
        end
      end)
    end
    return
  end

  -- 存在可用的客户端，附加到所有 gdscript 缓冲区
  for _, bufnr in ipairs(gdscript_bufs) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
      -- 清除标记，让 LSP 系统可以处理此缓冲区
      vim.b[bufnr].lsp_started = nil
      -- 检查是否已有 godot_editor 客户端附加到此缓冲区
      local clients = vim.lsp.get_clients({ name = "godot_editor", bufnr = bufnr })
      if #clients == 0 then
        -- 尝试附加到已存在的 godot_editor 客户端
        for _, client in ipairs(all_clients) do
          if client.rpc and client.rpc.handle and not vim.lsp.buf_is_attached(bufnr, client.id) then
            vim.lsp.buf_attach_client(bufnr, client.id)
            break
          end
        end
      end
    end
  end
end

-- 检查端口是否被占用
local function is_port_in_use(port)
  -- 方法1: 使用 ss 检查
  local ok, result = pcall(vim.fn.system, {
    "ss",
    "-tlnp",
    "sport",
    "= :" .. port,
  })
  if ok then
    -- ss 即使无匹配也会输出表头行，需要检查是否有数据行（包含端口号的行）
    for line in result:gmatch("[^\n]+") do
      if line:find(":" .. port) then
        return true
      end
    end
    return false
  end

  -- 方法2: 回退到 /proc/net/tcp 检查
  local f = io.open("/proc/net/tcp", "r")
  if f then
    local content = f:read("*a")
    f:close()
    local hex_port = string.format(":%04X", port)
    return content:find(hex_port) ~= nil
  end

  -- 方法3: 使用 /proc/net/tcp6
  local f6 = io.open("/proc/net/tcp6", "r")
  if f6 then
    local content = f6:read("*a")
    f6:close()
    local hex_port = string.format(":%04X", port)
    return content:find(hex_port) ~= nil
  end

  return false
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

  -- godotdev.setup() 之后，将 vim.lsp.config["gdscript"] 的配置
  -- 同步到主 LSP 系统的 _server_configs，使 start_server_with_config 可用
  if lsp_module_ok and lsp_module then
    local gd_lsp_config = vim.lsp.config["gdscript"]
    if gd_lsp_config and gd_lsp_config.cmd then
      if not lsp_module._server_configs then
        lsp_module._server_configs = {}
      end
      lsp_module._server_configs["godot_editor"] = vim.deepcopy(gd_lsp_config)
      lsp_module._server_configs["godot_editor"].filetypes = { "gdscript", "gd", "gdshader", "gdresource" }
    end
  end

  -- 先启动 Godot LSP 后台服务，确保端口就绪
  local server_started = start_godot_lsp_server()

  -- 等待端口就绪后再配置 LSP 客户端
  if server_started then
    -- 3 次重试，每次等待 10 秒
    local retry_count = 0
    local max_retries = 3
    local retry_delay = 10000 -- 10 秒

    local function try_attach_lsp()
      if is_port_in_use(6005) then
        -- 端口已就绪：
        -- 1. 先停止所有残留的 failed/stopped godot_editor 客户端
        --    （因为 godotdev.setup() 中的 vim.lsp.enable 可能在服务就绪前
        --     就尝试连接了，产生了 failed 客户端）
        local existing_clients = vim.lsp.get_clients({ name = "godot_editor" })
        local has_working = false
        for _, c in ipairs(existing_clients) do
          if c.rpc and c.rpc.handle then
            has_working = true
          else
            -- 清理无效客户端
            pcall(c.stop, c)
          end
        end

        -- 2. 如果没有可用的 godot_editor 客户端，通过 vim.lsp.enable 重启
        if not has_working then
          -- 确保 vim.lsp.config["gdscript"] 存在后再 enable
          if vim.lsp.config["gdscript"] and vim.lsp.config["gdscript"].cmd then
            vim.lsp.enable("gdscript")
          end
        end

        -- 3. 配置 godot-lsp.nvim
        setup_godot_lsp()

        -- 4. 延迟一下确保 LSP 客户端有时间连接，然后附加到缓冲区
        vim.defer_fn(function()
          godotdev_loaded = true
          ensure_gdscript_lsp_attached()
          vim.notify("🚀 Godot 开发工具已加载", vim.log.levels.INFO)
        end, 1000)
        return
      end

      retry_count = retry_count + 1
      if retry_count < max_retries then
        vim.defer_fn(try_attach_lsp, retry_delay)
      else
        -- 3 次重试均失败，报错但仍然尝试配置
        setup_godot_lsp()
        godotdev_loaded = true
        ensure_gdscript_lsp_attached()
        vim.notify(
          "❌ Godot LSP 服务启动失败（重试 "
            .. max_retries
            .. " 次后端口 6005 仍未就绪），请检查 Godot 是否正常运行",
          vim.log.levels.ERROR
        )
        vim.notify("🚀 Godot 开发工具已加载（LSP 服务未启动）", vim.log.levels.INFO)
      end
    end

    vim.defer_fn(try_attach_lsp, retry_delay)
  else
    -- 端口已被占用或启动失败，直接配置
    setup_godot_lsp()
    godotdev_loaded = true
    ensure_gdscript_lsp_attached()
    vim.notify("🚀 Godot 开发工具已加载（LSP 服务可能未启动）", vim.log.levels.INFO)
  end
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

-- 在导出的 index.html 中注入 console 日志拦截器
-- 让游戏运行时 print() 输出能通过 POST /log 发送回日志服务器
local function inject_console_logger(html_path)
  if vim.fn.filereadable(html_path) ~= 1 then
    return false
  end

  local f = io.open(html_path, "r")
  if not f then
    return false
  end
  local content = f:read("*a")
  f:close()

  -- 检查是否已经注入过（避免重复注入）
  if content:find("godot-console-logger") then
    return true
  end

  -- 要注入的 JS 代码：拦截 console 方法，通过 fetch 发送到 /log 端点
  local inject_script = [[
<script id="godot-console-logger">
// Godot Console Logger — 将游戏运行时 print() 日志发送到 Neovim 悬浮窗
(function() {
  var LOG_SERVER = '/log';
  var originalMethods = {};

  // 保存原始方法
  ['log', 'warn', 'error', 'info', 'debug'].forEach(function(level) {
    originalMethods[level] = console[level];
  });

  // 重写 console 方法
  function sendLog(level, args) {
    try {
      var msg = Array.prototype.map.call(args, function(arg) {
        if (typeof arg === 'object') {
          try { return JSON.stringify(arg); } catch(e) { return String(arg); }
        }
        return String(arg);
      }).join(' ');
      
      // 发送到日志服务器（使用 sendBeacon 或 fetch，避免阻塞游戏）
      var payload = JSON.stringify({ level: level, message: msg });
      if (navigator.sendBeacon) {
        navigator.sendBeacon(LOG_SERVER, payload);
      } else {
        fetch(LOG_SERVER, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: payload,
          keepalive: true
        }).catch(function() {});
      }
    } catch(e) {
      // 日志发送失败时回退到原始 console
      originalMethods['error']('[Godot Logger] 发送日志失败:', e);
    }
  }

  // 重写 console 方法
  ['log', 'warn', 'error', 'info', 'debug'].forEach(function(level) {
    console[level] = function() {
      // 调用原始方法（保持浏览器控制台也有输出）
      originalMethods[level].apply(console, arguments);
      // 发送到日志服务器
      sendLog(level, arguments);
    };
  });

  // 也捕获未处理的错误
  window.addEventListener('error', function(e) {
    sendLog('error', ['Uncaught:', e.message, 'at', e.filename + ':' + e.lineno]);
  });

  // 捕获 Promise 未处理拒绝
  window.addEventListener('unhandledrejection', function(e) {
    sendLog('warn', ['Unhandled Promise:', e.reason]);
  });

  console.log('[Godot Logger] ✅ 控制台日志拦截已启用，print() 输出将发送到 Neovim 悬浮窗');
})();
</script>
]]

  -- 在 </head> 标签前注入（或者在 </body> 前作为备选）
  local modified
  if content:find("</head>") then
    modified = content:gsub("</head>", inject_script .. "\n</head>", 1)
  elseif content:find("</body>") then
    modified = content:gsub("</body>", inject_script .. "\n</body>", 1)
  elseif content:find("</html>") then
    modified = content:gsub("</html>", inject_script .. "\n</html>", 1)
  else
    -- 最后手段：追加到文件末尾
    modified = content .. "\n" .. inject_script
  end

  f = io.open(html_path, "w")
  if not f then
    return false
  end
  f:write(modified)
  f:close()
  return true
end

-- 保存当前后台 job id，用于清理
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

  -- 自动创建导出目录（防止 Godot 因目录不存在而报错）
  local export_dir = root .. "/build/web"
  if vim.fn.isdirectory(export_dir) == 0 then
    vim.fn.mkdir(export_dir, "p")
    append_output(string.format("📁 自动创建导出目录: %s", export_dir))
  end

  local export_path = root .. "/build/web/index.html"
  local server_port = 8080

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "godot://export-web")
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "godot-export"
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false

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
  vim.wo[win].winhl = "NormalFloat:NormalFloat,FloatBorder:FloatBorder"

  -- 按 q 或 <C-c> 关闭悬浮窗
  local function close_float_win()
    cleanup_web_jobs()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.bo[buf].modified = false
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "", { callback = close_float_win, nowait = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<C-c>", "", { callback = close_float_win, nowait = true, silent = true })

  local function strip_ansi_codes(text)
    return text:gsub("\027%[[%d;]*%a", "")
  end

  local function append_output(text)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    vim.bo[buf].modifiable = true
    local clean_text = strip_ansi_codes(text)
    local lines = vim.split(clean_text, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
  end

  -- [ERROR] 自动停止机制：记录每一条 [ERROR]，发现重复或超时 1 秒则自动停止并打印全部记录
  local error_records = {}
  local first_error_time = nil
  local auto_stop_triggered = false

  local function check_error_auto_stop(line)
    if auto_stop_triggered then
      return true
    end

    -- 检查行中是否包含 [ERROR]
    if not line:find("%[ERROR%]") then
      return false
    end

    -- 记录这条 [ERROR]
    table.insert(error_records, line)
    if not first_error_time then
      first_error_time = vim.loop.now()
    end

    -- 条件1: 重复检查 — 当前 error 是否之前出现过
    local is_dup = false
    if #error_records >= 2 then
      for i = 1, #error_records - 1 do
        if error_records[i] == line then
          is_dup = true
          break
        end
      end
    end

    -- 条件2: 超时检查 — 从第一条 error 开始是否已过 1 秒
    local is_timeout = false
    if first_error_time and (vim.loop.now() - first_error_time >= 1000) then
      is_timeout = true
    end

    -- 任一条件满足则触发自动停止
    if not (is_dup or is_timeout) then
      return false
    end

    auto_stop_triggered = true

    -- 在悬浮窗中输出停止信息
    append_output("")
    append_output("⚠️ ========== [ERROR] 自动停止服务 ==========")
    append_output("检测到以下 [ERROR] 记录：")
    for i, err in ipairs(error_records) do
      append_output(string.format("  %d. %s", i, err))
    end
    append_output("")
    if is_dup then
      append_output("⏹ 停止原因：发现重复的 [ERROR] 记录")
    elseif is_timeout then
      append_output("⏹ 停止原因：第一条 [ERROR] 已超过 1 秒")
    end
    append_output("==========================================")
    append_output("")

    -- 同时把全部记录 print 到控制台（在 Neovim 中可通过 :messages 查看）
    print("")
    print("===== GodotExportWeb [ERROR] 全部记录 =====")
    for i, err in ipairs(error_records) do
      print(string.format("  %d. %s", i, err))
    end
    print("============================================")
    print("")

    -- 延迟一帧停止所有后台服务（避免在 job 回调中直接操作）
    vim.schedule(function()
      append_output("🛑 正在停止所有服务...")
      cleanup_web_jobs()
    end)

    return true
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
            check_error_auto_stop(line)
          end
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            local tagged = "[stderr] " .. line
            append_output(tagged)
            check_error_auto_stop(tagged)
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
      append_output("✅ 导出成功！注入日志拦截器到 index.html...")

      -- 注入 console 日志拦截 JS
      local log_server_script = vim.fn.stdpath("config") .. "/scripts/godot-log-server.js"
      local inject_ok = inject_console_logger(export_path)
      if inject_ok then
        append_output("✅ 已注入日志拦截器，游戏 print() 将显示在此窗口")
      else
        append_output("⚠️ 日志拦截器注入失败（可能是文件已被修改）")
      end

      append_output("")
      append_output("🚀 启动自定义日志服务器（替代 http-server）...")

      -- 使用自定义日志服务器（替代 http-server），同时接收游戏运行时日志
      local server_job = vim.fn.jobstart({ "node", log_server_script, root .. "/build/web", tostring(server_port) }, {
        cwd = root .. "/build/web",
        stdout_buffered = false,
        stderr_buffered = false,
        on_stdout = function(_, data)
          if data then
            for _, line in ipairs(data) do
              if line ~= "" then
                append_output(line)
                check_error_auto_stop(line)
              end
            end
          end
        end,
        on_stderr = function(_, data)
          if data then
            for _, line in ipairs(data) do
              if line ~= "" then
                local tagged = "[stderr] " .. line
                append_output(tagged)
                check_error_auto_stop(tagged)
              end
            end
          end
        end,
        on_exit = function(_, code)
          append_output("")
          append_output("🛑 日志服务已退出 (code=" .. code .. ")")
        end,
      })
      table.insert(web_jobs, server_job)

      append_output("")
      append_output(string.format("🌐 http://localhost:%d", server_port))
      append_output("")
      append_output("💡 关闭此窗口可自动停止所有服务")
      append_output("💡 游戏在浏览器中运行时，print() 日志会自动显示在此窗口")
    end,
  })
  table.insert(web_jobs, export_job)
end, {
  nargs = "?",
  complete = "file",
  desc = "导出 Godot 项目为 HTML5 并启动本地 HTTP 服务",
})

-- ============================================================
-- GodotInit: 一键初始化 Godot 项目基础框架
-- ============================================================
-- 基础框架包含：
--   project.godot            — 项目配置（含 Web 导出友好设置）
--   Main.gd                  — 入口脚本（含 fonts/ 目录下的 OTF 字体加载）
--   Main.tscn                — 入口场景（CanvasLayer + Label）
--   export_presets.cfg       — Web 导出预设
--   icon.svg                 — 默认图标
--   fonts/SourceHanSansHWSC-Regular.otf — 思源黑体等宽中文字体（从 fonts 目录解压）
--
-- 依赖文件：
--   /mnt/f6c8858d-4d92-4d0b-bf2f-e485fa194660/fonts/14_SourceHanSansHWSC.zip
--   解压后提供 SourceHanSansHWSC-Regular.otf 和 SourceHanSansHWSC-Bold.otf
-- ============================================================
vim.api.nvim_create_user_command("GodotInit", function(opts)
  local project_name = opts.args
  if project_name == nil or project_name == "" then
    project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    if project_name == "" or project_name == "/" then
      vim.notify("请指定项目名称: GodotInit 项目名", vim.log.levels.ERROR)
      return
    end
    vim.notify("未指定名称，使用当前目录: " .. project_name, vim.log.levels.INFO)
  end

  -- 目标目录：当前工作目录 或 新建子目录
  local target_dir
  if opts.args and opts.args ~= "" then
    target_dir = vim.fn.getcwd() .. "/" .. project_name
    if vim.fn.isdirectory(target_dir) == 0 then
      vim.fn.mkdir(target_dir, "p")
      vim.notify("创建项目目录: " .. target_dir, vim.log.levels.INFO)
    end
  else
    target_dir = vim.fn.getcwd()
  end

  -- 检查目标目录是否已有 project.godot
  local proj_file = target_dir .. "/project.godot"
  if vim.fn.filereadable(proj_file) == 1 then
    vim.notify("目录中已存在 project.godot，跳过初始化（避免覆盖）", vim.log.levels.WARN)
    return
  end

  local font_zip = "/mnt/f6c8858d-4d92-4d0b-bf2f-e485fa194660/fonts/14_SourceHanSansHWSC.zip"
  local stats = vim.uv.fs_stat(font_zip)
  if not stats then
    vim.notify("字体文件未找到: " .. font_zip, vim.log.levels.ERROR)
    return
  end

  -- 生成随机 UID（Godot 场景格式）
  local function gen_uid()
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local uid = ""
    for _ = 1, 12 do
      uid = uid .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    return "uid://" .. uid
  end

  local scene_uid = gen_uid()
  math.randomseed(os.time())

  -- ========== 1. project.godot ==========
  local project_godot = string.format(
    [[
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.
;
; Format:
;   [section] ; section goes between []
;   param=value ; assign values to parameters

config_version=5

[application]

config/name="%s"
run/main_scene="res://Main.tscn"
config/features=PackedStringArray("4.5", "Forward Plus")
config/icon="res://icon.svg"

[display]

window/size/viewport_width=960
window/size/viewport_height=640
window/size/mode=0
window/size/resizable=true
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"

[rendering]

renderer/rendering_method="mobile"
]],
    project_name
  )

  -- ========== 2. Main.gd ==========
  local main_gd = [[extends Node2D

# ============================================================
# 项目入口脚本
# 字体: SourceHanSansHWSC-Regular.otf（思源黑体等宽简体中文）
# 所有平台（含 Web）统一使用 OTF 字体文件渲染中文
# ============================================================

# --- 字体 ---
var game_font: Font

@onready var label: Label = $UI/Label

func _ready() -> void:
	# 直接 load 让 Godot 导入管线自动处理 OTF → FontFile
	game_font = load("res://fonts/SourceHanSansHWSC-Regular.otf")
	if game_font == null:
		push_error("无法加载字体！回退到系统 sans-serif")
		game_font = SystemFont.new()
		game_font.font_names = PackedStringArray(["sans-serif"])
	game_font.allow_system_fallback = true

	_apply_fonts()
	label.text = "Hello Godot!"

func _apply_fonts() -> void:
	var font_size := maxi(14, int(get_viewport_rect().size.y * 0.04))
	label.add_theme_font_override(&"font", game_font)
	label.add_theme_font_size_override(&"font_size", font_size)
]]

  -- ========== 3. Main.tscn ==========
  local main_tscn = string.format(
    [[
[gd_scene load_steps=2 format=3 uid="%s"]

[ext_resource type="Script" path="res://Main.gd" id="1_main"]

[node name="Main" type="Node2D"]
script = ExtResource("1_main")

[node name="UI" type="CanvasLayer" parent="."]

[node name="Label" type="Label" parent="UI"]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -20.0
offset_right = 200.0
offset_bottom = 20.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
horizontal_alignment = 1
vertical_alignment = 1
text = ""
]],
    scene_uid
  )

  -- ========== 4. export_presets.cfg ==========
  local export_presets = [[
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
html/canvas_resize_policy=2
progressive_web_app/enabled=false
progressive_web_app/offline_page=""
progressive_web_app/display=0
progressive_web_app/orientation=0
progressive_web_app/icon_144x144=""
progressive_web_app/icon_180x180=""
progressive_web_app/icon_512x512=""
progressive_web_app/background_color=Color(0, 0, 0, 1)
]]

  -- ========== 5. icon.svg ==========
  local icon_svg = [[
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <rect width="128" height="128" rx="24" fill="#478cbf"/>
  <rect x="8" y="8" width="112" height="112" rx="18" fill="#355d8a"/>
  <text x="64" y="88" text-anchor="middle"
        font-size="72" font-weight="bold"
        font-family="sans-serif" fill="#ffffff">G</text>
</svg>
]]

  -- ========== 写入文件 ==========
  local files = {
    { path = target_dir .. "/project.godot", content = project_godot },
    { path = target_dir .. "/Main.gd", content = main_gd },
    { path = target_dir .. "/Main.tscn", content = main_tscn },
    { path = target_dir .. "/export_presets.cfg", content = export_presets },
    { path = target_dir .. "/icon.svg", content = icon_svg },
  }

  for _, file in ipairs(files) do
    local f, err = io.open(file.path, "w")
    if not f then
      vim.notify("写入失败: " .. file.path .. " (" .. err .. ")", vim.log.levels.ERROR)
      return
    end
    f:write(file.content)
    f:close()
    vim.notify("✅ " .. vim.fn.fnamemodify(file.path, ":t"), vim.log.levels.INFO)
  end

  -- ========== 创建导出目录 ==========
  local export_dir = target_dir .. "/build/web"
  if vim.fn.isdirectory(export_dir) == 0 then
    vim.fn.mkdir(export_dir, "p")
    vim.notify("✅ build/web/ (导出目录)", vim.log.levels.INFO)
  end

  -- ========== 创建 fonts 目录并解压字体 ==========
  local fonts_dir = target_dir .. "/fonts"
  if vim.fn.isdirectory(fonts_dir) == 0 then
    vim.fn.mkdir(fonts_dir, "p")
  end
  vim.notify("⏳ 正在解压字体到 fonts/ ...", vim.log.levels.INFO)
  local unzip_cmd = { "unzip", "-o", "-j", font_zip, "-d", fonts_dir }
  local unzip_output = vim.fn.system(unzip_cmd)
  local unzip_rc = vim.v.shell_error
  if unzip_rc ~= 0 then
    vim.notify("解压字体失败: " .. unzip_output, vim.log.levels.ERROR)
    return
  end
  vim.notify("✅ fonts/SourceHanSansHWSC-Regular.otf", vim.log.levels.INFO)
  vim.notify("✅ fonts/SourceHanSansHWSC-Bold.otf", vim.log.levels.INFO)

  -- 刷新文件浏览器
  vim.cmd("silent! Lexplore")

  vim.notify("", vim.log.levels.INFO)
  vim.notify("🎉 Godot 项目初始化完成！", vim.log.levels.INFO)
  vim.notify("📂 " .. target_dir, vim.log.levels.INFO)
  vim.notify("", vim.log.levels.INFO)
  vim.notify("项目结构:", vim.log.levels.INFO)
  vim.notify("  fonts/                      — 字体目录", vim.log.levels.INFO)
  vim.notify("  fonts/SourceHanSansHWSC-*.otf — 思源黑体等宽中文字体", vim.log.levels.INFO)
  vim.notify("  Main.tscn               — 入口场景（CanvasLayer + Label）", vim.log.levels.INFO)
  vim.notify("  export_presets.cfg      — Web 导出预设", vim.log.levels.INFO)
  vim.notify("  icon.svg                — 默认图标", vim.log.levels.INFO)
end, {
  nargs = "?",
  desc = "初始化 Godot 项目基础框架（含中文字体、Web导出预设）",
})

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

-- 安全网：godotdev 加载后，新打开的 gdscript 缓冲区自动确保 LSP 附加
-- 这解决了主 LSP 系统 FileType autocmd 可能先于 godotdev 初始化执行，
-- 导致首次 LSP 客户端连接失败后无法自动重试的问题。
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gdscript", "gdresource", "gdshader" },
  callback = function(args)
    if godotdev_loaded then
      -- 延迟确保 godot_editor 客户端已完成启动
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(args.buf) then
          vim.b[args.buf].lsp_started = nil
          -- 通过主 LSP 系统触发完整的 LSP 启动/附加流程
          local lsp_ok, lsp_mod = pcall(require, "lsp")
          if lsp_ok and lsp_mod.start_lsp_for_filetype then
            lsp_mod.start_lsp_for_filetype(args.match, args.buf)
          end
        end
      end, 500)
    end
  end,
})

-- 退出时清理 Godot LSP 后台服务
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    stop_godot_lsp_server()
  end,
})

-- 导出模块，供 LspRestartAll 等外部模块调用
return {
  start_godot_lsp_server = start_godot_lsp_server,
  stop_godot_lsp_server = stop_godot_lsp_server,
  is_godot_project = is_godot_project,
  is_port_in_use = is_port_in_use,
  setup_godotdev = setup_godotdev,
  setup_godot_lsp = setup_godot_lsp,
  ensure_gdscript_lsp_attached = ensure_gdscript_lsp_attached,
  -- 可重置的 loaded 标记引用
  reset_loaded = function()
    godotdev_loaded = false
  end,
}

