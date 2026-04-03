-- 自动加载 lsp 目录下的所有语言服务器配置
local function load_lsp_configs()
  local configs = {}
  
  -- 加载所有 lsp 配置文件
  local lsp_dir = vim.fn.expand('<sfile>:p:h') .. '/lsp'
  print('搜索LSP配置文件在: ' .. lsp_dir)
  
  local files = vim.fn.glob(lsp_dir .. '/*.lua', false, true)
  
  if #files == 0 then
    print('未找到LSP配置文件，使用默认配置')
    -- 返回默认配置
    return {
      bashls = {},
      cssls = {},
      gopls = {},
      html = {},
      jsonls = {},
      lua_ls = {
        settings = {
          Lua = {
            runtime = { version = 'LuaJIT' },
            diagnostics = { globals = { 'vim' } },
            workspace = {
              library = vim.api.nvim_get_runtime_file('', true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      },
      pyright = {},
      rust_analyzer = {},
      ts_ls = {},
    }
  end
  
  print('找到 ' .. #files .. ' 个LSP配置文件')
  
  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ':t:r')
    print('  加载: ' .. name)
    
    -- 映射文件名到服务器名
    local server_name = name
    if name == 'bash' then server_name = 'bashls' end
    if name == 'css' then server_name = 'cssls' end
    if name == 'go' then server_name = 'gopls' end
    if name == 'html' then server_name = 'html' end
    if name == 'json' then server_name = 'jsonls' end
    if name == 'lua' then server_name = 'lua_ls' end
    if name == 'python' then server_name = 'pyright' end
    if name == 'rust' then server_name = 'rust_analyzer' end
    if name == 'typescript' then server_name = 'ts_ls' end
    
    local ok, config = pcall(dofile, file)
    if ok then
      configs[server_name] = config
      print('    成功: ' .. server_name)
    else
      print('    失败: ' .. server_name .. ' - ' .. tostring(config))
      configs[server_name] = {}
    end
  end
  
  return configs
end