-- lsp/configs/godot_editor.lua
-- Godot Editor LSP 配置存根
--
-- godotdev.nvim 插件负责实际管理 Godot LSP 连接（通过 vim.lsp.config 和 vim.lsp.enable），
-- 服务名称为 "godot_editor"。
-- 此文件仅作为配置存根，让主 LSP 系统（lsp/init.lua）的 load_server_config 能够成功加载，
-- 避免 "module not found" 错误日志。
--
-- 实际的 LSP 启动由 godotdev.nvim 处理，主 LSP 系统仅负责文件类型映射和附加。

return {}
