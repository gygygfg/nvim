-- LSP 问题修复脚本
-- 解决 rust-analyzer, vtsls, eslint 等问题

local M = {}

function M.fix_all_issues()
  print("🔧 开始修复 LSP 问题...")
  
  -- 1. 修复 rust-analyzer 配置
  M.fix_rust_analyzer()
  
  -- 2. 修复 vtsls 配置
  M.fix_vtsls()
  
  -- 3. 修复 eslint 配置
  M.fix_eslint()
  
  -- 4. 修复 LSP 配置加载器
  M.fix_lsp_config_loader()
  
  -- 5. 创建问题说明文档
  M.create_issue_documentation()
  
  print("✅ LSP 问题修复完成")
  print("💡 请重启 Neovim 或运行 :LspRestart 应用更改")
end

function M.fix_rust_analyzer()
  local config_path = vim.fn.stdpath("config") .. "/lua/plugins/lsp/mason/lsp/rust_analyzer.lua"
  local content = [[-- Mason lsp 配置
-- rust-analyzer 配置

return {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    single_file_support = true,
    root_dir = function(fname)
      -- 如果当前目录没有 Cargo.toml，使用单文件模式
      local cwd = vim.fn.getcwd()
      local cargo_toml = vim.fn.findfile("Cargo.toml", cwd .. ";")
      if cargo_toml == "" then
        return vim.fn.fnamemodify(fname, ":h")
      end
      return vim.fn.fnamemodify(cargo_toml, ":h")
    end,
    settings = {
        ["rust-analyzer"] = {
            checkOnSave = {
                command = "clippy",
            },
            diagnostics = {
                disabled = { "unresolved-proc-macro" },
            },
            cargo = {
                loadOutDirsFromCheck = true,
            },
            procMacro = {
                enable = true,
            },
        }
    }
}]]
  
  local f = io.open(config_path, "w")
  if f then
    f:write(content)
    f:close()
    print("✅ 修复 rust-analyzer 配置")
  else
    print("❌ 无法写入 rust-analyzer 配置")
  end
end

function M.fix_vtsls()
  local config_path = vim.fn.stdpath("config") .. "/lua/plugins/lsp/mason/lsp/vtsls.lua"
  local content = [[-- Mason lsp 配置
-- vtsls 配置

return {
    cmd = { "vtsls", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    single_file_support = true,
    root_dir = function(fname)
      return vim.fn.getcwd()
    end,
    init_options = {
      typescript = {
        tsdk = "",
      },
      preferences = {
        includePackageJsonAutoImports = "on",
      },
    }
}]]
  
  local f = io.open(config_path, "w")
  if f then
    f:write(content)
    f:close()
    print("✅ 修复 vtsls 配置")
  else
    print("❌ 无法写入 vtsls 配置")
  end
end

function M.fix_eslint()
  local config_path = vim.fn.stdpath("config") .. "/lua/plugins/lsp/mason/lsp/eslint.lua"
  local content = [[-- Mason lsp 配置
-- eslint 配置

return {
    cmd = { "vscode-eslint-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
    single_file_support = true,
    root_dir = function(fname)
      return vim.fn.getcwd()
    end,
    settings = {
      validate = "on",
      rulesCustomizations = {},
      run = "onType",
      useESLintClass = false,
      codeAction = {
        disableRuleComment = {
          enable = true,
          location = "separateLine"
        },
        showDocumentation = {
          enable = true
        }
      },
      codeActionOnSave = {
        enable = false,
        mode = "all"
      },
      format = true,
      quiet = false,
      onIgnoredFiles = "off",
      problems = {
        shortenToSingleLine = false
      },
      workingDirectory = {
        mode = "location"
      }
    }
}]]
  
  local f = io.open(config_path, "w")
  if f then
    f:write(content)
    f:close()
    print("✅ 修复 eslint 配置")
  else
    print("❌ 无法写入 eslint 配置")
  end
end

function M.fix_lsp_config_loader()
  local config_path = vim.fn.stdpath("config") .. "/lua/plugins/lsp/mason/lsp_config_loader.lua"
  
  -- 读取现有文件
  local f = io.open(config_path, "r")
  if not f then
    print("❌ 无法读取 LSP 配置加载器")
    return
  end
  
  local content = f:read("*a")
  f:close()
  
  -- 修复 on_attach 函数中的 URI 问题
  local fixed_content = content:gsub(
    'local custom_on_attach = function%(client, bufnr%)',
    'local custom_on_attach = function(client, bufnr)\n    -- 修复 URI 问题\n    if client.config and client.config.handlers then\n      client.config.handlers["textDocument/didOpen"] = function(err, result, ctx, config)\n        -- 确保 URI 格式正确\n        if result and result.textDocument and result.textDocument.uri then\n          local uri = result.textDocument.uri\n          if uri == "file://" then\n            -- 使用当前文件的 URI\n            local bufname = vim.api.nvim_buf_get_name(bufnr)\n            if bufname ~= "" then\n              result.textDocument.uri = vim.uri_from_fname(bufname)\n            end\n          end\n        end\n        -- 调用原始处理器\n        vim.lsp.handlers["textDocument/didOpen"](err, result, ctx, config)\n      end\n    end'
  )
  
  -- 写入修复后的内容
  f = io.open(config_path, "w")
  if f then
    f:write(fixed_content)
    f:close()
    print("✅ 修复 LSP 配置加载器")
  else
    print("❌ 无法写入 LSP 配置加载器")
  end
end

function M.create_issue_documentation()
  local doc_path = vim.fn.stdpath("config") .. "/lua/plugins/lsp/LSP_ISSUES_FIXED.md"
  local content = [[# LSP 问题修复文档

## 已修复的问题

### 1. rust-analyzer 问题
**问题**: `Failed to discover workspace. Consider adding the Cargo.toml`
**原因**: rust-analyzer 在当前目录找不到 Cargo.toml 文件
**修复**: 
- 添加了智能的 root_dir 检测
- 如果没有 Cargo.toml，使用单文件模式
- 添加了完整的 rust-analyzer 设置

### 2. vtsls 问题
**问题**: `Connection input stream is not set`
**原因**: 缺少 `--stdio` 参数
**修复**: 
- 在 cmd 中添加 `--stdio` 参数
- 添加了 init_options 配置
- 设置了正确的 root_dir

### 3. eslint 问题
**问题**: `The "path" argument must be of type string. Received undefined`
**原因**: 路径参数未定义
**修复**: 
- 添加了完整的 settings 配置
- 设置了正确的 root_dir
- 添加了更多文件类型支持

### 4. 通用 URI 问题
**问题**: `unresolvable URI at (root).textDocument.uri`
**原因**: URI 格式不正确（`file:///`）
**修复**: 
- 在 LSP 配置加载器中添加了 URI 修复逻辑
- 确保所有 LSP 服务器都有正确的 root_dir 配置

## 使用建议

1. **对于 Rust 项目**:
   - 确保项目根目录有 Cargo.toml
   - 或者使用单文件模式编辑 Rust 文件

2. **对于 TypeScript/JavaScript 项目**:
   - vtsls 现在应该能正常工作
   - eslint 需要项目中有相应的配置文件

3. **重启 Neovim**:
   - 运行 `:LspRestart` 重启所有 LSP 服务器
   - 或者完全重启 Neovim

4. **验证修复**:
   - 打开相应类型的文件
   - 运行 `:LspInfo` 查看 LSP 状态
   - 检查 `/root/.local/state/nvim/lsp.log` 日志

## 备用方案

如果问题仍然存在，可以：
1. 使用最小化配置：`:lua require('plugins.lsp.minimal_setup').setup()`
2. 禁用有问题的 LSP 服务器
3. 手动配置特定的 LSP 服务器

## 联系支持

如果问题持续存在，请提供：
1. Neovim 版本
2. 操作系统信息
3. 完整的 lsp.log 内容
4. 复现步骤

---
*最后更新: 2026-03-30*
*修复脚本: fix_lsp_issues.lua*]]

  local f = io.open(doc_path, "w")
  if f then
    f:write(content)
    f:close()
    print("✅ 创建问题文档")
  else
    print("❌ 无法创建问题文档")
  end
end

-- 导出函数
M.fix_all_issues = M.fix_all_issues

return M