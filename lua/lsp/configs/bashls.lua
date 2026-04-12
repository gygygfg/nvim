-- Bash语言服务器配置
return {
  settings = {
    bash = {
      shellcheck = {
        enabled = true,
        useWSLPath = false,
      },
    },
  },
  root_dir = vim.fs.dirname(vim.fs.find({ '.git' }, { upward = true })[1]),
}
