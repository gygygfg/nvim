-- 修复重复 LSP 客户端的脚本
local M = {}

function M.fix()
  print("=== 开始修复重复 LSP 客户端 ===")
  
  -- 1. 获取所有客户端
  local all_clients = vim.lsp.get_clients()
  print("当前 LSP 客户端总数: " .. #all_clients)
  
  -- 2. 按名称分组
  local clients_by_name = {}
  for _, client in ipairs(all_clients) do
    if not clients_by_name[client.name] then
      clients_by_name[client.name] = {}
    end
    table.insert(clients_by_name[client.name], client)
  end
  
  -- 3. 识别重复的客户端
  local duplicates = {}
  for name, client_list in pairs(clients_by_name) do
    if #client_list > 1 then
      duplicates[name] = client_list
      print("发现重复: " .. name .. " (" .. #client_list .. " 个实例)")
      for i, client in ipairs(client_list) do
        print("  实例 " .. i .. ": ID=" .. client.id .. ", 根目录=" .. (client.config and client.config.root_dir or "nil"))
      end
    end
  end
  
  -- 4. 清理重复的客户端
  local removed = 0
  for name, client_list in pairs(duplicates) do
    -- 保留配置最完整的那个（通常是有根目录和完整配置的）
    local keep_index = 1
    local best_score = 0
    
    for i, client in ipairs(client_list) do
      local score = 0
      if client.config and client.config.root_dir then
        score = score + 2
      end
      if client.config and client.config.settings and next(client.config.settings) ~= nil then
        score = score + 1
      end
      
      if score > best_score then
        best_score = score
        keep_index = i
      end
    end
    
    print("保留 " .. name .. " 的实例 " .. keep_index .. " (分数: " .. best_score .. ")")
    
    -- 停止其他实例
    for i, client in ipairs(client_list) do
      if i ~= keep_index then
        print("  停止实例 ID: " .. client.id)
        client.terminate()
        removed = removed + 1
      end
    end
  end
  
  -- 5. 重新附加客户端到当前缓冲区
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo.filetype
  
  if ft and ft ~= "" then
    print("\n重新附加 LSP 客户端到当前缓冲区 (" .. bufnr .. ", 文件类型: " .. ft .. ")")
    
    -- 获取应该为当前文件类型启动的服务器
    local lsp_module = require("lsp")
    local server_names = lsp_module.filetype_mappings[ft]
    
    if server_names then
      for _, server_name in ipairs(server_names) do
        local clients = vim.lsp.get_clients({ name = server_name })
        for _, client in ipairs(clients) do
          if not vim.lsp.buf_is_attached(bufnr, client.id) then
            -- 检查文件类型是否匹配
            local should_attach = true
            if client.config and client.config.filetypes then
              should_attach = false
              for _, client_ft in ipairs(client.config.filetypes) do
                if client_ft == ft then
                  should_attach = true
                  break
                end
              end
            end
            
            if should_attach then
              vim.lsp.buf_attach_client(bufnr, client.id)
              print("  附加 " .. server_name .. " (ID: " .. client.id .. ")")
            end
          end
        end
      end
    end
  end
  
  -- 6. 更新缓冲区标记
  vim.b[bufnr].lsp_started = true
  
  print("\n=== 修复完成 ===")
  print("已停止 " .. removed .. " 个重复的 LSP 客户端")
  print("剩余 LSP 客户端: " .. #vim.lsp.get_clients())
  
  vim.notify("已修复重复的 LSP 客户端", vim.log.levels.INFO)
end

-- 创建用户命令
vim.api.nvim_create_user_command("LspFixDuplicate", function()
  M.fix()
end, { desc = "修复重复的 LSP 客户端" })

return M