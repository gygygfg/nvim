-- LSP 配置加载器
-- 从新的 Mason 目录结构加载 LSP 配置

local M = {}

local function custom_notify(msg, level)
  level = level or vim.log.levels.INFO
  local opts = {
    title = "LSP 加载器",
    timeout = 3000,
  }
  vim.notify(msg, level, opts)
end

-- 扫描 LSP 配置目录
function M.scan_lsp_configs()
  local config_dir = vim.fn.stdpath("config") .. "/lua/plugins/lsp/mason/lsp"
  local configs = {}

  if vim.fn.isdirectory(config_dir) == 0 then
    custom_notify("❌ LSP 配置目录不存在: " .. config_dir, vim.log.levels.ERROR)
    return configs
  end

  local ok, iter, state = pcall(vim.loop.fs_scandir, config_dir)
  if not ok then
    custom_notify("❌ 无法扫描目录: " .. config_dir, vim.log.levels.ERROR)
    return configs
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(iter, state)
    if not name then break end

    if name:match("%.lua$") then
      local config_name = name:gsub("%.lua$", "")
      table.insert(configs, config_name)
    end
  end

  return configs
end

-- 加载单个 LSP 配置
function M.load_lsp_config(server_name)
  -- 首先尝试直接加载配置
  local ok, config = pcall(require, "plugins/lsp/mason/lsp/" .. server_name)

  if not ok then
    -- 如果加载失败，检查是否是 lspconfig.util 错误
    local error_msg = tostring(config)
    if error_msg:match("lspconfig%.util") then
      -- 尝试使用简化的加载方式
      config = M.load_config_without_lspconfig_util(server_name)
      if config then
        return config
      end
    end

    custom_notify("❌ 无法加载 LSP 配置: " .. server_name .. " - " .. error_msg, vim.log.levels.ERROR)
    return nil
  end

  if type(config) ~= "table" then
    custom_notify("⚠️ LSP 配置格式错误: " .. server_name, vim.log.levels.WARN)
    return nil
  end

  return config
end

-- 加载配置但不依赖 lspconfig.util
function M.load_config_without_lspconfig_util(server_name)
  local filepath = vim.fn.stdpath("config") .. "/lua/plugins/lsp/mason/lsp/" .. server_name .. ".lua"
  local f = io.open(filepath, "r")

  if not f then
    return nil
  end

  local content = f:read("*a")
  f:close()

  -- 移除对 lspconfig.util 的引用
  -- 使用更简单的方法：直接替换整个 require 调用
  local fixed_content = content:gsub('require%("lspconfig%.util"%)%.root_pattern', 'nil')

  -- 尝试解析修改后的内容
  local chunk = "return " .. fixed_content
  local ok, result = pcall(loadstring or load, chunk)

  if ok and type(result) == "function" then
    ok, result = pcall(result)
  end

  if ok and type(result) == "table" then
    return result
  end

  -- 如果解析失败，返回一个基本的配置
  return {
    filetypes = { "txt" },                      -- 默认文件类型
    single_file_support = true,
    cmd = { "echo", "LSP server not configured" } -- 添加默认 cmd 字段
  }
end

-- 设置所有 LSP 服务器
function M.setup_all_lsp_servers()
  -- 确保 cmp_nvim_lsp 已加载
  local capabilities
  local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if ok_cmp then
    capabilities = cmp_nvim_lsp.default_capabilities()
  else
    capabilities = vim.lsp.protocol.make_client_capabilities()
    custom_notify("⚠️ cmp_nvim_lsp 未找到，使用默认 capabilities", vim.log.levels.WARN)
  end

  -- 添加自定义的 on_attach 函数
  local custom_on_attach = function(client, bufnr)
    -- 标准 LSP 按键映射
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, bufopts)

    -- 启用自动补全触发
    vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
  end

  local configs = M.scan_lsp_configs()
  local loaded_servers = {}

  -- 创建按需启动的函数
  local function setup_lsp_for_buffer(server_name, config)
    local buf_path = vim.api.nvim_buf_get_name(0)
    if not buf_path or buf_path == "" then
      return false
    end

    local existing_clients = vim.lsp.get_active_clients({ name = server_name })
    if #existing_clients > 0 then
      return true
    end

    -- 智能检测根目录
    local root_dir = vim.fn.fnamemodify(buf_path, ":p:h")
    if root_dir == "/root" then
      local config_dir = vim.fn.stdpath("config")
      if config_dir and config_dir ~= "/root" then
        root_dir = config_dir
      end
    end

    local start_config = {
      name = server_name,
      cmd = config.cmd,
      root_dir = config.root_dir or root_dir,
      capabilities = config.capabilities or capabilities,
      settings = config.settings,
      on_attach = config.on_attach or custom_on_attach,
      filetypes = config.filetypes,
      single_file_support = config.single_file_support,
      init_options = config.init_options,
      handlers = config.handlers,
    }

    -- 移除 nil 值
    for k, v in pairs(start_config) do
      if v == nil then
        start_config[k] = nil
      end
    end

    local ok, err = pcall(vim.lsp.start, start_config)
    if ok then
      table.insert(loaded_servers, server_name)
      custom_notify("✅ " .. server_name .. " 已启动", vim.log.levels.INFO)
      return true
    else
      custom_notify("❌ " .. server_name .. " 启动失败: " .. tostring(err), vim.log.levels.ERROR)
      return false
    end
  end -- setup_lsp_for_buffer 函数结束

  -- 为每个 LSP 服务器设置自动命令
  for _, server_name in ipairs(configs) do
    local config = M.load_lsp_config(server_name)

    if config then
      -- 确保配置有 cmd 字段
      if not config.cmd then
        config.cmd = { "echo", "LSP server not configured: " .. server_name }
        custom_notify("⚠️ " .. server_name .. " 缺少 cmd 字段，使用默认值", vim.log.levels.WARN)
      end

      -- 验证 cmd 字段是否为 table
      if type(config.cmd) ~= "table" then
        custom_notify("❌ " .. server_name .. " 的 cmd 字段不是 table: " .. type(config.cmd), vim.log.levels.ERROR)
        config.cmd = { "echo", "Invalid cmd configuration for: " .. server_name }
      end

      -- 添加 capabilities
      config.capabilities = capabilities

      -- 为每个文件类型设置自动命令
      if config.filetypes then
        for _, filetype in ipairs(config.filetypes) do
          vim.api.nvim_create_autocmd("FileType", {
            pattern = filetype,
            callback = function()
              setup_lsp_for_buffer(server_name, config)
            end,
            desc = "启动 " .. server_name .. " LSP 服务器"
          })
        end
      end

      -- 也尝试立即启动（如果当前缓冲区有合适的文件类型）
      local current_ft = vim.bo.filetype
      if config.filetypes and vim.tbl_contains(config.filetypes, current_ft) then
        setup_lsp_for_buffer(server_name, config)
      end
    else
      custom_notify("❌ " .. server_name .. " 配置加载失败", vim.log.levels.ERROR)
    end
  end

  -- custom_notify("✅ LSP 自动命令设置完成: " .. #configs .. " 个服务器", vim.log.levels.INFO)
  return loaded_servers
end

return M
