-- lsp/configs/godot_editor.lua
-- Godot Editor LSP 配置
--
-- godotdev.nvim 插件负责实际管理 Godot LSP 连接，
-- 此配置提供基本的 cmd 信息（通过 vim.lsp.rpc.connect 连接本机 Godot LSP 端口），
-- 让主 LSP 系统（lsp/init.lua）能够正确启动客户端。

local host = "127.0.0.1"
local port = 6005

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.typeDefinition = nil -- suppress unsupported typeDefinition

return {
  cmd = vim.lsp.rpc.connect(host, port),
  filetypes = { "gdscript", "gd", "gdshader", "gdresource" },
  root_markers = { "project.godot", ".git" },
  capabilities = capabilities,
  name = "godot_editor",
}
