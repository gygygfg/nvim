# LSP 配置问题修复总结

## 问题识别
1. **vtsls 问题**：缺少 `--stdio` 参数，导致连接错误
2. **Rust 分析器问题**：无法在 `/root/.config/nvim/lua/plugins/lsp` 中找到项目
3. **Lua 语言服务器**：拒绝加载 `/root` 目录作为工作区
4. **ESLint**：路径参数错误，收到 undefined
5. **clangd**：URI 解码错误（空文件路径问题）

## 修复措施

### 1. vtsls 配置修复 (vtsls.lua)
- 添加了 `--stdio` 参数到 cmd 字段
- 修复了连接流设置问题

### 2. Rust 分析器配置改进 (rust_analyzer.lua)
- 添加了单文件支持：`standalone = true`
- 添加了 `standaloneConfig.enable = true`
- 保留了基本的 cargo 和检查设置

### 3. Lua 语言服务器配置改进 (lua_ls.lua)
- 添加了工作区限制设置：
  - `checkThirdParty = false` - 避免扫描第三方库
  - `maxPreload = 1000` - 限制预加载文件数量
  - `preloadFileSize = 100` - 限制预加载文件大小

### 4. LSP 配置加载器重大改进 (lsp_config_loader.lua)
- **按需启动机制**：改为使用 FileType 自动命令按需启动 LSP
- **安全检查**：避免在空缓冲区或无文件路径时启动 LSP
- **智能根目录检测**：
  - 优先使用缓冲区文件目录
  - 避免使用 `/root` 作为工作区
  - 使用 Neovim 配置目录作为替代
- **错误处理改进**：更好的错误通知和恢复机制

### 5. ESLint 配置改进 (eslint.lua)
- 扩展了支持的文件类型
- 添加了验证和工作目录设置

## 语法错误修复
- **问题**：`lsp_config_loader.lua` 第242行附近缺少 `end` 语句
- **修复**：在 `setup_lsp_for_buffer` 函数后添加了缺失的 `end` 语句
- **验证**：创建了测试脚本验证语法正确性

## 新的启动机制
1. **按需启动**：LSP 服务器只在打开相应文件类型时启动
2. **自动命令**：为每个 LSP 服务器的文件类型设置 FileType 自动命令
3. **安全检查**：确保有有效的文件路径后才启动服务器
4. **避免重复**：检查是否已有相同服务器的活动客户端

## 测试建议
1. **重新启动 Neovim** 以应用所有更改
2. **测试 vtsls**：打开一个 `.ts` 或 `.js` 文件
3. **测试 rust_analyzer**：打开一个 `.rs` 文件
4. **测试 lua_ls**：打开一个 `.lua` 文件
5. **运行测试脚本**：执行 `:luafile /root/.config/nvim/test_lsp_fix.lua`

## 验证方法
1. 检查 LSP 日志：`/root/.local/state/nvim/lsp.log`
2. 使用 `:LspInfo` 命令查看活动的 LSP 服务器
3. 观察通知消息确认服务器启动状态

## 预期结果
- vtsls 应该正常启动，不再有连接错误
- rust_analyzer 应该支持单文件模式
- lua_ls 应该避免扫描整个 `/root` 目录
- 所有 LSP 服务器应该只在有实际文件时启动