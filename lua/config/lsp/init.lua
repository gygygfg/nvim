-- LSP 配置模块
-- 整合了 config.lsp.lua 的所有功能

-- 自定义通知函数
local function custom_notify(msg, level)
  level = level or vim.log.levels.INFO
  local opts = {
    title = "LSP",
    timeout = 300,
  }
  vim.notify(msg, level, opts)
end

load.addPack({
  --LSP服务器管理器
  --'williamboman/mason.nvim'
  {src = "https://github.com/mason-org/mason.nvim"},
  -- Mason与LSP配置的桥梁
  {src = "https://github.com/williamboman/mason-lspconfig.nvim"},
  -- Neovim内置LSP客户端
  {src = "https://github.com/neovim/nvim-lspconfig"},
  -- LSP进度显示
  {src = "https://github.com/j-hui/fidget.nvim"},
  -- LSP代码操作UI
  {src = "https://github.com/stevearc/dressing.nvim"},
  -- 更好的诊断显示
  {src = "https://github.com/folke/trouble.nvim"},
})

local M = {}

-- 服务器列表
local servers = {}

local function scan_servers()
  -- 扫描 servers 目录获取服务器列表
  local servers_dir = vim.fn.stdpath("config") .. "/lua/config/lsp/servers"
  local scanned_servers = {}

  if vim.fn.isdirectory(servers_dir) == 1 then
    local ok, iter, state = pcall(vim.loop.fs_scandir, servers_dir)
    if ok then
      while true do
        local name, _ = vim.loop.fs_scandir_next(iter, state)
        if not name then break end

        if name:match("%.lua$") then
          local server_name = name:gsub("%.lua$", "")
          table.insert(scanned_servers, server_name)
        end
      end
    end
  end

  return scanned_servers
end

-- 初始化服务器列表
servers = scan_servers()

function M.find_and_install(description)
  -- 1. 通过描述查找和安装 LSP 服务器
  -- 加载 Mason Finder
  local finder_ok, mason_finder = pcall(require, 'config.lsp.mason_finder')
  if not finder_ok then
    custom_notify("❌ Mason Finder 未找到", vim.log.levels.ERROR)
    return nil
  end

  -- 搜索匹配的包
  local results = mason_finder.search_packages(description)
  if #results == 0 then
    custom_notify("❌ 未找到匹配的包: " .. description, vim.log.levels.WARN)
    return nil
  end

  -- 显示搜索结果
  local msg = "🔍 找到 " .. #results .. " 个匹配的包:\n"
  for i, pkg in ipairs(results) do
    if i <= 10 then -- 只显示前10个结果
      msg = msg .. "  " .. i .. ". " .. pkg.name .. " - " .. pkg.description .. "\n"
    end
  end
  if #results > 10 then
    msg = msg .. "  ... 还有 " .. (#results - 10) .. " 个结果"
  end
  custom_notify(msg, vim.log.levels.INFO)

  -- 让用户选择要安装的包
  vim.ui.select(results, {
    prompt = "请选择要安装的包:",
    format_item = function(item)
      return item.name .. " - " .. item.description
    end,
  }, function(choice)
    if not choice then return end

    local server_name = choice.name

    -- 检查是否已经在服务器列表中
    local already_in_list = false
    for _, existing_server in ipairs(servers) do
      if existing_server == server_name then
        already_in_list = true
        break
      end
    end

    if not already_in_list then
      table.insert(servers, server_name)
      custom_notify("📝 已添加到服务器列表: " .. server_name, vim.log.levels.INFO)

      -- 创建对应的服务器配置文件
      local servers_dir = vim.fn.stdpath("config") .. "/lua/config/lsp/servers"
      local server_file = servers_dir .. "/" .. server_name .. ".lua"

      -- 确保目录存在
      if vim.fn.isdirectory(servers_dir) == 0 then
        vim.fn.mkdir(servers_dir, "p")
      end

      -- 如果配置文件不存在，创建默认配置
      if vim.fn.filereadable(server_file) == 0 then
        local default_config = string.format([[
        -- %s 配置
        -- 自动生成的配置（通过描述查找）

        return {
          -- 文件类型（需要根据实际情况修改）
          filetypes = {""},

          -- 服务器设置
          settings = {
            -- 添加你的自定义设置
          },

          -- 根目录模式
          root_dir = function(fname)
            return vim.fn.getcwd()
          end,
        }
        ]], server_name)

        vim.fn.writefile(vim.split(default_config, "\n"), server_file)
        custom_notify("📄 已创建默认配置文件: " .. server_file, vim.log.levels.INFO)
      end

      -- 安装包
      local mason_ok, _ = pcall(require, 'mason')
      if mason_ok then
        local registry = require("mason-registry")
        local pkg = registry.get_package(server_name)
        if pkg then
          if not pkg:is_installed() then
            custom_notify("📦 开始安装: " .. server_name, vim.log.levels.INFO)
            pkg:install()
          else
            custom_notify("✅ 包已安装: " .. server_name, vim.log.levels.INFO)
          end
        else
          custom_notify("❌ 无法找到包: " .. server_name, vim.log.levels.ERROR)
        end
      else
        custom_notify("❌ Mason 未加载，无法安装包", vim.log.levels.ERROR)
      end
    else
      custom_notify("✅ 服务器已在列表中: " .. server_name, vim.log.levels.INFO)
    end
  end)

  return true
end

function M.find_for_current_filetype()
  -- 2. 为当前文件类型查找 LSP
  local ft = vim.bo.filetype
  if not ft or ft == "" then
    custom_notify("❌ 当前缓冲区没有文件类型", vim.log.levels.ERROR)
    return nil
  end

  -- 加载 Mason Finder
  local finder_ok, mason_finder = pcall(require, 'config.lsp.mason_finder')
  if not finder_ok then
    custom_notify("❌ Mason Finder 未找到", vim.log.levels.ERROR)
    return nil
  end

  -- 查找工具链
  local toolchain = mason_finder.find_toolchain(ft)
  if not toolchain or not toolchain.lsp then
    custom_notify("❌ 未找到 " .. ft .. " 的 LSP 服务器", vim.log.levels.WARN)
    return nil
  end

  local lsp_package = toolchain.lsp
  local server_name = lsp_package.name

  -- 检查是否已经在服务器列表中
  local already_in_list = false
  for _, existing_server in ipairs(servers) do
    if existing_server == server_name then
      already_in_list = true
      break
    end
  end

  if not already_in_list then
    table.insert(servers, server_name)
    custom_notify("📝 已添加到服务器列表: " .. server_name, vim.log.levels.INFO)

    -- 创建对应的服务器配置文件
    local servers_dir = vim.fn.stdpath("config") .. "/lua/config/lsp/servers"
    local server_file = servers_dir .. "/" .. server_name .. ".lua"

    -- 确保目录存在
    if vim.fn.isdirectory(servers_dir) == 0 then
      vim.fn.mkdir(servers_dir, "p")
    end

    -- 如果配置文件不存在，创建默认配置
    if vim.fn.filereadable(server_file) == 0 then
      local default_config = string.format([[
      -- %s 配置
      -- 自动生成的配置（为 %s 文件类型）

      return {
        -- 文件类型
        filetypes = {"%s"},

        -- 服务器设置
        settings = {
          -- 添加你的自定义设置
        },

        -- 根目录模式
        root_dir = function(fname)
          return vim.fn.getcwd()
        end,
      }
      ]], server_name, ft, ft)

      vim.fn.writefile(vim.split(default_config, "\n"), server_file)
      custom_notify("📄 已创建默认配置文件: " .. server_file, vim.log.levels.INFO)
    end
  end

  return server_name
end

function M.get_servers()
  -- 3. 获取所有服务器
  return servers
end

function M.reload()
  -- 4. 重新加载配置
  servers = scan_servers()
  custom_notify("🔄 LSP 配置已重新加载", vim.log.levels.INFO)
  custom_notify("📋 当前服务器列表: " .. table.concat(servers, ", "), vim.log.levels.INFO)
end

function M.install_all()
  -- 5. 安装所有缺失的服务器
  local mason_ok, _ = pcall(require, 'mason')
  if not mason_ok then
    custom_notify("❌ Mason 未加载", vim.log.levels.ERROR)
    return
  end

  local registry = require("mason-registry")

  local installed_count = 0
  local already_installed_count = 0

  for _, server_name in ipairs(servers) do
    local pkg = registry.get_package(server_name)
    if pkg then
      if not pkg:is_installed() then
        custom_notify("📦 开始安装: " .. server_name, vim.log.levels.INFO)
        pkg:install()
        installed_count = installed_count + 1
      else
        already_installed_count = already_installed_count + 1
      end
    else
      custom_notify("❌ 无法找到包: " .. server_name, vim.log.levels.WARN)
    end
  end

  if installed_count > 0 then
    custom_notify("✅ 已安装 " .. installed_count .. " 个服务器", vim.log.levels.INFO)
  end

  if already_installed_count > 0 then
    custom_notify("📋 已有 " .. already_installed_count .. " 个服务器已安装", vim.log.levels.INFO)
  end

  if installed_count == 0 and already_installed_count == 0 then
    custom_notify("📭 没有需要安装的服务器", vim.log.levels.INFO)
  end
end

local function create_user_commands()
  -- 8. 创建用户命令
  -- 通过描述查找和安装 LSP 服务器
  vim.api.nvim_create_user_command("LspFind", function(opts)
    local args = opts.fargs
    if #args == 0 then
      custom_notify("用法: LspFind <描述片段>", vim.log.levels.INFO)
      custom_notify("示例: LspFind python language server", vim.log.levels.INFO)
      return
    end

    local description = table.concat(args, " ")
    M.find_and_install(description)
  end, {
  nargs = "*",
  desc = "通过描述片段查找和安装 LSP 服务器",
})

vim.api.nvim_create_user_command("LspFindForFiletype", function()
  -- 为当前文件类型查找和安装 LSP
  local server_name = M.find_for_current_filetype()
  if server_name then
    custom_notify("✅ 已为当前文件类型配置 LSP: " .. server_name, vim.log.levels.INFO)
  end
end, {desc = "为当前文件类型查找和安装 LSP 服务器",})

-- 列出所有已配置的服务器
vim.api.nvim_create_user_command("LspList", function()
  local servers = M.get_servers()

  if #servers == 0 then
    custom_notify("📭 未配置任何 LSP 服务器", vim.log.levels.INFO)
    return
  end

  local msg = "📋 已配置 " .. #servers .. " 个 LSP 服务器:\n"
  for i, server in ipairs(servers) do
    msg = msg .. "  " .. i .. ". " .. server .. "\n"
  end
  custom_notify(msg, vim.log.levels.INFO)
end, { desc = "列出所有已配置的 LSP 服务器",})

vim.api.nvim_create_user_command("LspReload", function()
  -- 重新加载 LSP 配置
  M.reload()
end, {desc = "重新加载 LSP 配置",
  })

  -- 安装所有缺失的服务器
  vim.api.nvim_create_user_command("LspInstallAll", function()
    M.install_all()
  end, {desc = "安装所有缺失的 LSP 服务器",})

  vim.api.nvim_create_user_command("MasonSearch", function(opts)
    -- 使用 Mason Finder 搜索包
    local args = opts.fargs
    if #args == 0 then
      custom_notify("用法: MasonSearch <关键词>", vim.log.levels.INFO)
      custom_notify("示例: MasonSearch python formatter", vim.log.levels.INFO)
      return
    end

    local keyword = table.concat(args, " ")

    -- 加载 Mason Finder
    local finder_ok, mason_finder = pcall(require, 'config.lsp.mason_finder')
    if not finder_ok then
      custom_notify("❌ Mason Finder 未找到", vim.log.levels.ERROR)
      return
    end

    local results = mason_finder.search_packages(keyword)
    if #results == 0 then
      custom_notify("❌ 未找到匹配的包: " .. keyword, vim.log.levels.WARN)
      return
    end

    local msg = "🔍 找到 " .. #results .. " 个匹配的包:\n"
    for i, pkg in ipairs(results) do
      if i <= 15 then -- 只显示前15个结果
        msg = msg .. "  " .. i .. ". " .. pkg.name .. " - " .. pkg.description .. "\n"
      end
    end
    if #results > 15 then
      msg = msg .. "  ... 还有 " .. (#results - 15) .. " 个结果"
    end
    custom_notify(msg, vim.log.levels.INFO)
  end, {
  nargs = "*",
  desc = "使用 Mason Finder 搜索包",
})

-- 查找当前文件类型的完整工具链
vim.api.nvim_create_user_command("MasonToolchain", function()
  local ft = vim.bo.filetype
  if not ft or ft == "" then
    custom_notify("❌ 当前缓冲区没有文件类型", vim.log.levels.ERROR)
    return
  end

  -- 加载 Mason Finder
  local finder_ok, mason_finder = pcall(require, 'config.lsp.mason_finder')
  if not finder_ok then
    custom_notify("❌ Mason Finder 未找到", vim.log.levels.ERROR)
    return
  end

  local toolchain = mason_finder.find_toolchain(ft)
  if not toolchain then
    custom_notify("❌ 未找到 " .. ft .. " 的工具链", vim.log.levels.WARN)
    return
  end

  local msg = "🔧 " .. ft .. " 工具链:\n"

  if toolchain.lsp then
    msg = msg .. "  • LSP: " .. toolchain.lsp.name .. " - " .. toolchain.lsp.description .. "\n"
  end

  if toolchain.formatter then
    msg = msg .. "  • 格式化: " .. toolchain.formatter.name .. " - " .. toolchain.formatter.description .. "\n"
  end

  if toolchain.linter then
    msg = msg .. "  • 代码检查: " .. toolchain.linter.name .. " - " .. toolchain.linter.description .. "\n"
  end

  if toolchain.dap then
    msg = msg .. "  • 调试器: " .. toolchain.dap.name .. " - " .. toolchain.dap.description .. "\n"
  end

  custom_notify(msg, vim.log.levels.INFO)
end, {desc = "显示当前文件类型的完整工具链",})

custom_notify("✅ LSP 命令已创建", vim.log.levels.INFO)
end

-- 在 setup 函数中配置 Mason
M.setup = function()
  -- 创建用户命令
  create_user_commands()

  -- 使用 load.require 延迟加载 Mason 插件
  load.require('mason', {
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗"
      }
    }
  })

  -- 使用 load.require 延迟加载 Mason LSP 插件
  load.require('mason-lspconfig', {
    ensure_installed = servers,
    automatic_installation = true,
  })

  -- 延迟执行 LSP 服务器配置
  load.defer_fn(function()
    -- 为每个服务器设置 LSP 配置
    local configured_count = 0
    local skipped_count = 0

    for _, server_name in ipairs(servers) do
      -- 尝试加载服务器特定配置
      local config_path = "config.lsp.servers." .. server_name
      local ok, custom_config = pcall(require, config_path)

      if not ok then
        custom_notify("⚠️  跳过服务器 " .. server_name .. ": 无法加载配置 - " .. tostring(custom_config), vim.log.levels.WARN)
        skipped_count = skipped_count + 1
      elseif not custom_config then
        custom_notify("⚠️  跳过服务器 " .. server_name .. ": 配置为空", vim.log.levels.WARN)
        skipped_count = skipped_count + 1
      else
        local server_config = custom_config

        -- 检查是否是被禁用的服务器
        if server_config._disabled then
          custom_notify("⏸️  跳过已禁用的服务器: " .. server_name, vim.log.levels.INFO)
          skipped_count = skipped_count + 1
        else
          custom_notify("📄 加载自定义配置: " .. server_name, vim.log.levels.INFO)

          -- 检查配置是否包含必要的字段
          if not server_config.cmd then
            custom_notify("⚠️  服务器 " .. server_name .. " 缺少 cmd 字段，跳过配置", vim.log.levels.WARN)
            skipped_count = skipped_count + 1
          else
            -- 检查命令是否可执行
            local cmd_exists = false
            local cmd_name = "unknown"
            if server_config.cmd and server_config.cmd[1] then
              cmd_name = server_config.cmd[1]
              local handle = io.popen("command -v " .. cmd_name .. " 2>/dev/null")
              if handle then
                local result = handle:read("*a")
                handle:close()
                cmd_exists = result ~= "" and result ~= nil
              end
            end

            if not cmd_exists then
              custom_notify("⚠️  服务器命令不存在: " .. server_name .. " -> " .. cmd_name, vim.log.levels.WARN)
              custom_notify("💡 使用 :LspInstallAll 安装缺失的服务器", vim.log.levels.INFO)
              -- 不跳过，仍然配置服务器，但记录警告
              server_config._cmd_missing = true
              server_config._cmd_name = cmd_name
            else
              custom_notify("✅ 服务器命令可用: " .. server_name .. " -> " .. cmd_name, vim.log.levels.INFO)
            end

            -- 使用 Neovim 0.12 的新 API 配置服务器
            local config_success, config_error = pcall(function()
              vim.lsp.config(server_name, server_config)
            end)

            if config_success then
              custom_notify("✅ 配置服务器: " .. server_name, vim.log.levels.INFO)
              configured_count = configured_count + 1

              -- 为文件类型创建自动命令来启用服务器（只在命令存在时）
              if server_config.filetypes and #server_config.filetypes > 0 and not server_config._cmd_missing then
                for _, ft in ipairs(server_config.filetypes) do
                  load.nvim_create_autocmd('FileType', {
                    pattern = ft,
                    callback = function()
                      local enable_success, enable_error = pcall(function()
                        vim.lsp.enable(server_name)
                      end)

                      if enable_success then
                        custom_notify("🚀 为 " .. ft .. " 文件启用服务器: " .. server_name, vim.log.levels.INFO)
                      else
                        custom_notify("❌ 无法为 " .. ft .. " 文件启用服务器 " .. server_name .. ": " .. tostring(enable_error),
                        vim.log.levels.ERROR)
                      end
                    end,
                    group = vim.api.nvim_create_augroup('LspAutoEnable_' .. server_name, { clear = true })
                  })
                end
                custom_notify("🔧 为文件类型设置自动启用: " .. server_name, vim.log.levels.INFO)
              elseif server_config._cmd_missing then
                custom_notify("⏸️  服务器 " .. server_name .. " 命令不存在，跳过自动启用", vim.log.levels.INFO)
              end
            else
              custom_notify("❌ 无法配置服务器 " .. server_name .. ": " .. tostring(config_error), vim.log.levels.ERROR)
              skipped_count = skipped_count + 1
            end
          end
        end
      end
    end

    -- 记录到日志文件以便调试
    local log_msg = "LSP 配置完成: " .. configured_count .. " 个服务器已配置, " .. skipped_count .. " 个跳过"
    vim.notify(log_msg, vim.log.levels.INFO, { title = "LSP 配置报告" })

    -- 初始化
    custom_notify("✅ LSP 配置模块已加载", vim.log.levels.INFO)
  end, 100)  -- 延迟 100ms 执行，确保其他插件已加载
end

vim.schedule(function()
  -- 延迟调用 setup 函数，确保所有依赖已加载
  M.setup()
end)

return M
