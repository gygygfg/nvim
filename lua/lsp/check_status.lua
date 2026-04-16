-- 检查当前 LSP 状态
local function check_status()
  print("=== 当前 LSP 状态检查 ===")
  
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype
  
  print("当前缓冲区: " .. bufnr)
  print("文件类型: " .. (ft or "无"))
  print("lsp_started 标记: " .. tostring(vim.b[bufnr].lsp_started))
  
  -- 获取所有客户端
  local all_clients = vim.lsp.get_clients()
  print("\n所有 LSP 客户端 (" .. #all_clients .. " 个):")
  
  local clients_by_name = {}
  for _, client in ipairs(all_clients) do
    if not clients_by_name[client.name] then
      clients_by_name[client.name] = 0
    end
    clients_by_name[client.name] = clients_by_name[client.name] + 1
    
    print("  - " .. client.name .. " (ID: " .. client.id .. ")")
    print("    根目录: " .. (client.config and client.config.root_dir or "nil"))
    print("    文件类型: " .. (client.config and client.config.filetypes and table.concat(client.config.filetypes, ", ") or "未配置"))
    print("    附加到当前缓冲区: " .. (vim.lsp.buf_is_attached(bufnr, client.id) and "是" or "否"))
  end
  
  -- 检查重复
  print("\n重复检查:")
  local has_duplicates = false
  for name, count in pairs(clients_by_name) do
    if count > 1 then
      print("  ⚠️  " .. name .. ": " .. count .. " 个实例 (重复!)")
      has_duplicates = true
    else
      print("  ✓ " .. name .. ": " .. count .. " 个实例")
    end
  end
  
  if has_duplicates then
    print("\n建议运行: :LspFixDuplicate")
  else
    print("\n✓ 没有发现重复的 LSP 客户端")
  end
  
  print("\n=== 检查完成 ===")
end

-- 创建用户命令
vim.api.nvim_create_user_command("LspCheckStatus", check_status, { desc = "检查 LSP 状态" })

-- 立即运行检查
check_status()