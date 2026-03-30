-- LSP 调试脚本
local function debug_lsp()
  print("=== LSP 调试开始 ===")
  
  -- 1. 检查 vim.lsp.config 是否可用
  if vim.lsp.config then
    print("✅ vim.lsp.config 已可用")
  else
    print("❌ vim.lsp.config 不可用")
  end
  
  -- 2. 检查 cmp_nvim_lsp 是否可用
  local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if ok_cmp then
    print("✅ cmp_nvim_lsp 已加载")
  else
    print("❌ cmp_nvim_lsp 未加载: " .. tostring(cmp_nvim_lsp))
  end
  
  -- 3. 测试加载单个配置
  local loader = require("plugins.lsp.mason.lsp_config_loader")
  
  -- 测试 bashls 配置
  print("\n测试 bashls 配置:")
  local bashls_config = loader.load_lsp_config("bashls")
  if bashls_config then
    print("  ✅ 配置加载成功")
    print("  cmd 类型:", type(bashls_config.cmd))
    print("  cmd 值:", vim.inspect(bashls_config.cmd))
    print("  filetypes:", vim.inspect(bashls_config.filetypes))
  else
    print("  ❌ 配置加载失败")
  end
  
  -- 4. 测试 vim.lsp.start()
  print("\n测试 vim.lsp.start():")
  if bashls_config then
    -- 确保有 cmd
    if not bashls_config.cmd then
      bashls_config.cmd = {"bash-language-server", "start"}
    end
    
    -- 添加 capabilities
    local capabilities
    if ok_cmp then
      capabilities = cmp_nvim_lsp.default_capabilities()
    else
      capabilities = vim.lsp.protocol.make_client_capabilities()
    end
    bashls_config.capabilities = capabilities
    
    local ok, err = pcall(function()
      vim.lsp.start({
        name = "bashls-debug",
        config = bashls_config
      })
    end)
    
    if ok then
      print("  ✅ vim.lsp.start() 成功")
    else
      print("  ❌ vim.lsp.start() 失败: " .. tostring(err))
    end
  end
  
  -- 5. 检查 Mason 状态
  print("\n检查 Mason 状态:")
  local ok_mason, mason = pcall(require, "mason")
  if ok_mason then
    print("  ✅ Mason 已加载")
    
    -- 检查已安装的包
    local registry = mason.get_registry()
    local installed = registry.get_installed_packages()
    print("  已安装包数量:", #installed)
    
    -- 检查 bash-language-server
    local bash_pkg = registry.get_package("bash-language-server")
    if bash_pkg then
      print("  bash-language-server 状态:", bash_pkg:is_installed() and "已安装" or "未安装")
    else
      print("  bash-language-server 未找到")
    end
  else
    print("  ❌ Mason 未加载: " .. tostring(mason))
  end
  
  print("\n=== LSP 调试结束 ===")
end

-- 运行调试
debug_lsp()