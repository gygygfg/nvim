-- lua/plugins/treesitter.lua
-- Treesitter 语法高亮配置 (Neovim 0.12+ 内置支持)

-- 不再需要 nvim-treesitter，Neovim 0.12+ 已内置 treesitter 支持
-- 使用内置的 treesitter 模块

-- 安装解析器 (首次运行时可能需要手动执行 :TSInstall lua vim vimdoc bash 等)
local ensure_installed = {
  "lua",
  "vim",
  "vimdoc",
  "bash",
  "python",
  "javascript",
  "typescript",
  "html",
  "css",
  "json",
}

-- 设置基础高亮
vim.opt.syntax = "enable"

-- 仅为正常文件类型启用 treesitter (排除 notify, lspinfo 等特殊缓冲区)
vim.api.nvim_create_autocmd("FileType", {
  pattern = ensure_installed,
  callback = function()
    local success, err = pcall(vim.treesitter.start)
    if not success then
      -- Silently fail if parser not available
    end
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo.foldmethod = "expr"
  end,
})

-- 自动安装解析器 (如果需要)
vim.api.nvim_create_user_command("TSInstallAll", function()
  for _, parser in ipairs(ensure_installed) do
    pcall(vim.cmd, "TSInstall " .. parser)
  end
  vim.notify("Treesitter parsers installed: " .. table.concat(ensure_installed, ", "), vim.log.levels.INFO)
end, {})

-- vim.notify("Treesitter configured. Run :TSInstallAll to install parsers, or install individually with :TSInstall <lang>",vim.log.levels.INFO)
