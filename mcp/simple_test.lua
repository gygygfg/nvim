-- 简单的 MCP 测试脚本
print("=== MCP 服务简单测试 ===")

-- 1. 检查 mcphub 模块
local mcphub_ok, mcphub = pcall(require, "mcphub")
if not mcphub_ok then
  print("❌ 错误: mcphub 模块未找到")
  print("请运行: :Lazy install ravitemer/mcphub.nvim")
  return
end
print("✅ mcphub 模块加载成功")

-- 2. 检查服务器配置 - 使用正确的 API
local state = mcphub.get_state()
if not state then
  print("❌ 错误: 无法获取 MCP Hub 状态")
  return
end

if state.server_state and state.server_state.servers then
  local server_count = #state.server_state.servers
  print("✅ 找到 " .. server_count .. " 个已加载的服务器:")
  
  for _, server in ipairs(state.server_state.servers) do
    print("  - " .. (server.name or "未知"))
    print("    状态: " .. (server.state or "未知"))
    if server.config then
      print("    命令: " .. (server.config.command or "无"))
      if server.config.args then
        print("    参数: " .. table.concat(server.config.args, " "))
      end
    end
  end
else
  print("⚠️  服务器状态未初始化或为空")
  print("请检查 MCP Hub 是否已正确启动")
end