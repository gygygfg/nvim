-- Bash语言服务器配置
-- 注意：bashls v5 读取的设置段为 bashIde（不是 bash），字段为平铺的
-- shellcheckPath / globPattern / shfmt.path 等。
return {
  name = "bashls",
  cmd = { "bash-language-server", "start" },
  settings = {
    bashIde = {
      -- 非递归 glob，避免在 cwd 为 / 等场景下全盘扫描
      globPattern = "*@(.sh|.inc|.bash|.command)",
      -- shellcheck 由 mason 安装到 ~/.local/share/nvim/mason/bin
      shellcheckPath = "shellcheck",
    },
  },
  -- 由 Neovim 按 buffer 解析根目录，避免加载期按 cwd 计算并回退到 /
  root_markers = { ".git" },
  filetypes = { "sh", "bash", "zsh" },
}
