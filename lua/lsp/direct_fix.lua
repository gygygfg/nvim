-- 直接修复重复的 lua_ls 客户端
print("=== 直接修复 lua_ls 重复问题 ===")

-- 获取所有 lua_ls 客户端
local lua_clients = vim.lsp.get_clients({ name = "lua_ls" })
print("找到 " .. #lua_clients .. " 个 lua_ls 客户端")

if #lua_clients <= 1 then
  print("✓ 没有发现重复的 lua_ls 客户端")
  return
end

-- 显示客户端信息
for i, client in ipairs(lua_clients) do
  print("客户端 " .. i .. ":")
  print("  ID: " .. client.id)
  print("  根目录: " .. (client.config and client.config.root_dir or "nil"))
  print("  设置: " .. (client.config and client.config.settings and "有" or "无"))
  
  -- 检查附加的缓冲区
  local attached_buffers = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.lsp.buf_is_attached(bufnr, client.id) then
      table.insert(attached_buffers, bufnr)
    end
  end
  print("  附加到缓冲区: " .. #attached_buffers .. " 个")
end

-- 决定保留哪个客户端
-- 优先保留有根目录和完整配置的客户端
local keep_client = nil
local best_score = -1

for i, client in ipairs(lua_clients) do
  local score = 0
  
  -- 有根目录的得2分
  if client.config and client.config.root_dir then
    score = score + 2
  end
  
  -- 有完整设置的得1分
  if client.config and client.config.settings and next(client.config.settings) ~= nil then
    score = score + 1
  end
  
  -- 附加到当前缓冲区的得1分
  local current_buf = vim.api.nvim_get_current_buf()
  if vim.lsp.buf_is_attached(current_buf, client.id) then
    score = score + 1
  end
  
  print("客户端 " .. i .. " 分数: " .. score)
  
  if score > best_score then
    best_score = score
    keep_client = client
  end
end

if keep_client then
  print("\n保留客户端 ID: " .. keep_client.id .. " (分数: " .. best_score .. ")")
  
  -- 停止其他客户端
  local removed = 0
  for _, client in ipairs(lua_clients) do
    if client.id ~= keep_client.id then
      print("停止客户端 ID: " .. client.id)
      client.terminate()
      removed = removed + 1
    end
  end
  
  print("\n已停止 " .. removed .. " 个重复的 lua_ls 客户端")
  
  -- 确保保留的客户端附加到当前缓冲区
  local current_buf = vim.api.nvim_get_current_buf()
  if not vim.lsp.buf_is_attached(current_buf, keep_client.id) then
    print("附加客户端 " .. keep_client.id .. " 到当前缓冲区")
    vim.lsp.buf_attach_client(current_buf, keep_client.id)
  end
  
  vim.notify("已修复 lua_ls 重复问题", vim.log.levels.INFO)
else
  print("错误: 无法确定要保留哪个客户端")
end

print("\n=== 修复完成 ===")