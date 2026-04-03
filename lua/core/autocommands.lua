local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- 创建自动命令组
local mygroup = augroup("MyConfig", { clear = true })

-- 从 local_conf.lua 迁移的自动命令

-- 根据文件类型设置缩进
autocmd("FileType", {
  -- 缩进2格的文件类型
  pattern = {
    "lua",
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "json",
    "css",
    "html",
    "xml",
    "yaml",
    "markdown",
    "sh",
    "bash",
    "zsh",
    "php",
    "ruby",
    "vim",
    "terraform",
    "hcl",
    "dockerfile",
    "yaml.docker-compose"
  },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.bo.shiftwidth = 2 -- 某些语言使用 2 空格缩进
    vim.bo.tabstop = 2
    vim.opt_local.expandtab = true
  end,
  group = mygroup
})

autocmd("FileType", {
  -- 缩进4格的文件类型
  pattern = {
    "python",
    "java",
    "c",
    "cpp",
    "go",
    "rust",
    "swift",
    "kotlin",
    "scala",
    "cs",
    "dart",
    "perl",
    "fortran"
  },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.bo.shiftwidth = 4 -- 某些语言使用 2 空格缩进
    vim.bo.tabstop = 4
    vim.opt_local.expandtab = true
  end,
  group = mygroup
})

-- 缩进3格的文件类型
autocmd("FileType", {
  pattern = {
    "haskell",
    "puppet",
    "smarty"
  },
  callback = function()
    vim.opt_local.tabstop = 3
    vim.opt_local.shiftwidth = 3
    vim.opt_local.softtabstop = 3
    vim.bo.shiftwidth = 3 -- 某些语言使用 2 空格缩进
    vim.bo.tabstop = 3
    vim.opt_local.expandtab = true
  end,
  group = mygroup
})

-- 特殊文件类型设置
autocmd("FileType", {
  pattern = { "make" },
  callback = function()
    vim.opt_local.noexpandtab = true -- makefile 必须使用制表符
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
  group = mygroup
})

-- 保存时自动格式化
autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local filetype = vim.bo.filetype
    local sensitive_filetypes = { "yaml", "python", "yml", "py", "dockerfile" } -- 缩进敏感的文件
    local is_sensitive = false
    for _, ft in ipairs(sensitive_filetypes) do
      if filetype == ft then
        is_sensitive = true
        break
      end
    end

    -- 检查是否有可用的LSP格式化功能
    local function has_lsp_formatting()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      for _, client in ipairs(clients) do
        if client.supports_method("textDocument/formatting") then
          return true
        end
      end
      return false
    end

    -- LSP格式化函数
    local function formatWithLSP(show_msg)
      local has_formatting = has_lsp_formatting()
      if has_formatting then
        -- 保存光标位置
        local save_cursor = vim.fn.getpos(".")

        -- 使用LSP格式化
        vim.lsp.buf.format({
          async = false, -- 同步格式化，确保在保存前完成
          filter = function(client)
            -- 只使用支持格式化的客户端
            return client.supports_method("textDocument/formatting")
          end
        })

        -- 恢复光标位置
        vim.fn.setpos(".", save_cursor)

        if show_msg then
          vim.defer_fn(function()
            vim.notify("已使用LSP格式化", vim.log.levels.INFO, {
              title = "格式化",
              timeout = 2000,
            })
          end, 100)
        end
        return true
      end
      return false
    end

    -- 原有的gg=G格式化函数
    local function formatWithGG(show_msg)
      if not is_sensitive then
        local save_cursor = vim.fn.getpos(".")
        vim.cmd("silent! normal! gg=G")
        vim.fn.setpos(".", save_cursor)
        if show_msg then
          vim.defer_fn(function()
            vim.notify("已使用 gg=G 格式化", vim.log.levels.INFO, {
              title = "格式化",
              timeout = 2000,
            })
          end, 100) -- 短暂延迟确保格式化完成
        end
      end
    end

    -- 优先使用LSP格式化，如果不可用则使用gg=G
    local lsp_success = formatWithLSP(true)
    if not lsp_success then
      formatWithGG(true)
    end
  end,
  group = mygroup
})

-- 可选：为特定文件类型添加额外的格式化设置
autocmd("FileType", {
  pattern = { "python" },
  callback = function()
    -- 如果安装了 black，可以使用它来格式化 Python 代码
    if vim.fn.executable("black") == 1 then
      vim.opt_local.formatprg = "black -q - 2>/dev/null"
    end
  end,
  group = mygroup
})

autocmd("FileType", {
  pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact", "json", "css", "html" },
  callback = function()
    -- 如果安装了 prettier，可以使用它来格式化前端代码
    if vim.fn.executable("prettier") == 1 then
      vim.opt_local.formatprg = "prettier --stdin-filepath % 2>/dev/null"
    end
  end,
  group = mygroup
})

autocmd('InsertEnter', {
  -- 检测剪贴板中的文本长度，如果很长则提示使用 paste 模式
  callback = function()
    local clipboard = vim.fn.getreg('+')
    if clipboard and #clipboard > 200 then -- 超过200个字符
      vim.defer_fn(function()
        vim.notify('检测到大段文本，按 F2 可切换 paste 模式避免缩进问题',
        vim.log.levels.INFO, {
          title = '粘贴提示',
          timeout = 3000
        })
      end, 100)
    end
  end,
  group = mygroup
})

-- 原有的自动命令
autocmd({ "InsertLeave", "TextChanged" }, {
  -- 自动保存
  group = mygroup,
  pattern = "*",
  callback = function()
    if vim.fn.expand("%") ~= "" and vim.bo.modifiable then
      vim.cmd("silent! write")
    end
  end
})

autocmd("BufEnter", {
  -- 自动切换目录到当前文件
  group = mygroup,
  callback = function()
    vim.cmd("silent! lcd %:p:h")
  end
})

local function open_lsp_info()
  -- 查找已存在的LSP信息缓冲区
  local existing_buf = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match('lspinfo') then
      existing_buf = buf
      break
    end
  end

  -- 复用现有缓冲区或创建新的
  local buf = existing_buf or vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, 'lspinfo')

  -- 在当前窗口显示缓冲区
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- 执行checkhealth命令
  vim.cmd('checkhealth vim.lsp')
end

-- 重新定义LspInfo命令
vim.api.nvim_create_user_command('LspInfo', open_lsp_info, { desc = 'Show LSP information in reusable buffer' })

autocmd("VimEnter", {
  -- 查看插件加载情况
  group = mygroup,
  callback = function()
    vim.api.nvim_create_user_command("PacksStatus", function()
      -- 创建查看插件状态的命令
      -- 尝试读取 nvim-pack-lock.json 文件来获取插件列表
      local lock_file = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
      local file = io.open(lock_file, "r")

      if not file then
        vim.notify("Cannot find nvim-pack-lock.json", vim.log.levels.WARN)
        return
      end

      local content = file:read("*all")
      file:close()

      -- 解析 JSON 文件
      local ok, data = pcall(vim.json.decode, content)
      if not ok then
        vim.notify("Failed to parse nvim-pack-lock.json", vim.log.levels.ERROR)
        return
      end

      -- 获取插件列表
      local plugins = {}
      local plugin_names = {}
      if data.plugins then
        for name, plugin_data in pairs(data.plugins) do
          table.insert(plugins, {
            name = name,
            url = plugin_data.src,
            rev = plugin_data.rev
          })
          table.insert(plugin_names, name)
        end
      end

      -- 按名称排序插件
      table.sort(plugin_names)

      -- 分类插件
      local loaded_plugins = {}
      local installed_plugins = {}

      for _, plugin_name in ipairs(plugin_names) do
        local plugin_data = data.plugins[plugin_name]
        local plugin_rev = plugin_data.rev
        local short_rev = plugin_rev:sub(1, 8)

        -- 检查插件是否已加载（使用 package.loaded 检查）
        local loaded = package.loaded[plugin_name] ~= nil

        -- 尝试其他可能的模块名
        if not loaded then
          -- 尝试去掉 .nvim 后缀
          local name_without_nvim = plugin_name:gsub("%.nvim$", "")
          loaded = package.loaded[name_without_nvim] ~= nil
        end

        if not loaded then
          -- 尝试去掉 -nvim 后缀
          local name_without_dash_nvim = plugin_name:gsub("-nvim$", "")
          loaded = package.loaded[name_without_dash_nvim] ~= nil
        end

        if loaded then
          table.insert(loaded_plugins, {
            name = plugin_name,
            rev = short_rev
          })
        else
          table.insert(installed_plugins, {
            name = plugin_name,
            rev = short_rev
          })
        end
      end

      -- 创建浮动窗口显示插件状态
      local lines = { "Plugin Status (vim.pack):", "" }

      -- 显示已加载的插件
      if #loaded_plugins > 0 then
        table.insert(lines, "已加载的插件:")
        for _, plugin in ipairs(loaded_plugins) do
          table.insert(lines, string.format("  • %s ✓ [%s]", plugin.name, plugin.rev))
        end
        table.insert(lines, "")
      end

      -- 显示已安装但未加载的插件
      if #installed_plugins > 0 then
        table.insert(lines, "已安装但未加载的插件:")
        for _, plugin in ipairs(installed_plugins) do
          table.insert(lines, string.format("  • %s ○ [%s]", plugin.name, plugin.rev))
        end
        table.insert(lines, "")
      end

      -- 显示统计信息
      table.insert(lines, string.format("Total plugins: %d", #plugins))
      table.insert(lines, string.format("Loaded: %d", #loaded_plugins))
      table.insert(lines, string.format("Installed: %d", #installed_plugins))

      -- 显示浮动窗口
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

      local width = math.max(unpack(vim.tbl_map(function(line)
        return #line
      end, lines))) + 2

      local height = #lines + 2

      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = math.min(width, vim.o.columns - 4),
        height = math.min(height, vim.o.lines - 4),
        col = math.floor((vim.o.columns - math.min(width, vim.o.columns - 4)) / 2),
        row = math.floor((vim.o.lines - math.min(height, vim.o.lines - 4)) / 2),
        style = "minimal",
        border = "rounded",
        title = "Plugin Status",
        title_pos = "center"
      })

      -- 设置只读
      vim.api.nvim_buf_set_option(buf, "modifiable", false)
      vim.api.nvim_buf_set_option(buf, "readonly", true)

      -- 添加退出键映射
      vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, "n", "<C-c>", ":q<CR>", { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", ":q<CR>", { noremap = true, silent = true })
    end, { desc = "查看插件加载情况" })
  end
})

autocmd("LspAttach", {
  -- 查看LSP加载情况
  group = mygroup,
  callback = function(args)
    local bufnr = args.buf

    -- 自动刷新LSP信息缓冲区（如果存在）
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(buf):match('lspinfo') then
        -- 查找显示LSP信息的窗口
        local target_win = nil
        for _, w in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(w) == buf then
            target_win = w
            break
          end
        end

        -- 如果找到则刷新内容
        if target_win then
          vim.api.nvim_win_call(target_win, function()
            vim.cmd('checkhealth vim.lsp')
          end)
        end
      end
    end

    -- 创建查看当前缓冲区LSP信息的命令
    vim.api.nvim_buf_create_user_command(bufnr, "LspInfo", function()
      local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
      if #clients == 0 then
        vim.notify("No LSP client attached to this buffer", vim.log.levels.WARN)
        return
      end

      local lines = { "LSP Information for current buffer:" }
      for _, client in ipairs(clients) do
        table.insert(lines, string.format("  • %s (id: %d)", client.name, client.id))
        table.insert(lines, string.format("    - Root directory: %s", client.config.root_dir or "N/A"))
        table.insert(lines, string.format("    - File types: %s", table.concat(client.config.filetypes or {}, ", ")))
        table.insert(lines,
        string.format("    - Server capabilities: %d features", #vim.tbl_keys(client.server_capabilities or {})))
      end

      -- 在浮动窗口中显示信息
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

      local width = math.max(unpack(vim.tbl_map(function(line)
        return #line
      end, lines))) + 2

      local height = #lines + 2

      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = math.min(width, vim.o.columns - 4),
        height = math.min(height, vim.o.lines - 4),
        col = math.floor((vim.o.columns - math.min(width, vim.o.columns - 4)) / 2),
        row = math.floor((vim.o.lines - math.min(height, vim.o.lines - 4)) / 2),
        style = "minimal",
        border = "rounded",
        title = "LSP Info",
        title_pos = "center"
      })

      -- 设置只读
      vim.api.nvim_buf_set_option(buf, "modifiable", false)
      vim.api.nvim_buf_set_option(buf, "readonly", true)

      -- 添加退出键映射
      vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
      vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", ":q<CR>", { noremap = true, silent = true })
    end, { desc = "Show LSP information for current buffer" })

    -- 创建查看所有LSP客户端状态的命令
    vim.api.nvim_create_user_command("LspStatus", function()
      local clients = vim.lsp.get_active_clients()
      if #clients == 0 then
        vim.notify("No active LSP clients", vim.log.levels.INFO)
        return
      end

      local lines = { "Active LSP Clients:" }
      for _, client in ipairs(clients) do
        local attached_buffers = {}
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local buf_clients = vim.lsp.get_active_clients({ bufnr = buf })
          for _, buf_client in ipairs(buf_clients) do
            if buf_client.id == client.id then
              table.insert(attached_buffers, buf)
              break
            end
          end
        end

        table.insert(lines, string.format(
          "  • %s (id: %d): %d buffers attached",
          client.name, client.id, #attached_buffers
        ))
      end

      vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
    end, { desc = "Show status of all LSP clients" })

    -- 创建查看LSP服务器能力的命令
    vim.api.nvim_buf_create_user_command(bufnr, "LspCapabilities", function()
      local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
      if #clients == 0 then
        vim.notify("No LSP client attached to this buffer", vim.log.levels.WARN)
        return
      end

      for _, client in ipairs(clients) do
        local lines = { "LSP Capabilities for " .. client.name .. ":" }

        -- 检查各种能力
        local caps = client.server_capabilities
        if caps.completionProvider then
          table.insert(lines, "  • Completion: ✓")
        end
        if caps.definitionProvider then
          table.insert(lines, "  • Go to definition: ✓")
        end
        if caps.referencesProvider then
          table.insert(lines, "  • Find references: ✓")
        end
        if caps.hoverProvider then
          table.insert(lines, "  • Hover: ✓")
        end
        if caps.signatureHelpProvider then
          table.insert(lines, "  • Signature help: ✓")
        end
        if caps.documentFormattingProvider then
          table.insert(lines, "  • Format document: ✓")
        end
        if caps.documentRangeFormattingProvider then
          table.insert(lines, "  • Format range: ✓")
        end
        if caps.codeActionProvider then
          table.insert(lines, "  • Code actions: ✓")
        end
        if caps.renameProvider then
          table.insert(lines, "  • Rename: ✓")
        end

        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
      end
    end, { desc = "Show LSP server capabilities" })
  end
})

-- 从 local_conf.lua 迁移的其他设置

-- 创建 :Paste 命令
vim.api.nvim_create_user_command('Paste', function()
  -- 提供简单的 :Paste 命令
  vim.o.paste = true
  vim.notify('已启用 paste 模式，粘贴完成后会自动关闭',
  vim.log.levels.INFO, {
    title = '粘贴模式',
    timeout = 2000
  })
  -- 自动进入插入模式
  vim.cmd('startinsert')
  -- 插入模式离开后自动关闭 paste 模式
  vim.api.nvim_create_autocmd('InsertLeave', {
    once = true,
    callback = function()
      vim.o.paste = false
      vim.notify('已自动关闭 paste 模式',
      vim.log.levels.INFO, {
        title = '粘贴模式',
        timeout = 1500
      })
    end,
    group = mygroup
  })
end, { desc = '启用 paste 模式进行粘贴' })

-- 诊断配置
vim.diagnostic.config({
  -- 简化诊断提示
  virtual_text = {
    enabled = false, -- 禁用行内诊断提示
    prefix = "■"
  },
  float = {
    border = "none"
  }
})

-- 设置悬浮文档样式（手机端不易触达）
vim.lsp.handlers.hover = function(_, result, ctx, config)
  config = config or {}
  config.border = "none"
  vim.lsp.handlers.hover(_, result, ctx, config)
end

-- ==================== 全局配置更改提示禁用 ====================
-- 禁用所有配置更改检测提示，避免干扰

-- 设置全局变量，禁用配置更改提示
vim.g.disable_config_change_prompt = true
vim.g.silent_config_reload = true

-- 全局拦截配置更改消息
local original_notify = vim.notify
vim.notify = function(msg, level, opts)
  -- 过滤掉配置更改相关的提示
  if type(msg) == "string" then
    -- 检查是否包含配置更改相关关键词
    local config_change_keywords = {
      "Config Change Detected",
      "Press ENTER or type command to continue",
      "Reloading",
      "配置已更改",
      "重新加载",
      "提交成功:",
      "Git:"
    }

    for _, keyword in ipairs(config_change_keywords) do
      if string.find(msg, keyword) then
        -- 静默处理，不显示提示
        return
      end
    end
  end

  -- 调用原始的通知函数
  return original_notify(msg, level, opts)
end

-- 禁用所有插件配置更改提示
autocmd("User", {
  pattern = "LazyReload",
  callback = function()
    -- 静默处理 Lazy.nvim 的重载
    vim.cmd("silent! echo ''")
    vim.cmd("redraw")
  end,
  group = mygroup
})

-- 通用配置文件更改静默处理
autocmd("BufWritePost", {
  pattern = "*.lua",
  callback = function(args)
    local filename = vim.fn.fnamemodify(args.file, ":t")

    -- 检查是否是配置文件
    local config_files = {
      "codecompanion.lua",
      "local_conf.lua",
      "keymaps.lua",
      "nvim_venv.lua",
      "init.lua"
    }

    for _, config_file in ipairs(config_files) do
      if filename == config_file then
        -- 静默处理配置文件更新
        vim.defer_fn(function()
          vim.notify(filename .. " 配置已更新", vim.log.levels.INFO, {
            title = "配置更新",
            timeout = 1000,          -- 1秒后自动消失
            hide_from_history = true -- 不保存到历史
          })
        end, 100)

        -- 防止显示 "Press ENTER or type command to continue" 提示
        vim.cmd("silent! echo ''")
        vim.cmd("redraw")
        break
      end
    end
  end,
  group = mygroup
})

if vim.g.config_change_detected then
  -- 尝试覆盖常见的配置更改检测
  local function silent_config_change_handler()
    -- 覆盖可能的配置更改检测函数
    -- 什么都不做，静默处理
    return true
  end
  vim.g.config_change_detected = silent_config_change_handler
end
