# Git Commit 快捷键使用说明

## 功能概述
已成功配置 `<leader>gc` 快捷键来执行自定义的 git commit 功能。

## 使用方法

### 1. 普通模式 (Normal Mode)
- 按下 `<leader>gc`（默认 `<leader>` 是空格键）
- 会弹出一个输入框让你输入提交信息
- 输入提交信息后按回车
- 系统会自动执行 `git commit -am '你的提交信息'`

### 2. 可视模式 (Visual Mode)
- 选中一些文本
- 按下 `<leader>gc`
- 选中的文本会自动填充为默认提交信息
- 你可以修改或直接按回车确认

## 快捷键详情
- `<leader>gc` - 执行 git commit -am 并输入提交信息
- 描述: "[Git] 提交 (自定义)"

## 配置位置
配置位于: `/root/.config/nvim/lua/keymaps.lua` 中的 `M.fugitive()` 函数

## 测试方法
1. 在 Neovim 中打开一个 git 仓库中的文件
2. 确保有未提交的更改
3. 按下 `<leader>gc`
4. 输入提交信息
5. 查看执行结果

## 注意事项
- 这个功能会覆盖 vim-fugitive 默认的 `<leader>gc` 快捷键
- 如果你需要恢复原来的功能，可以修改 keymaps.lua 文件
- 确保在执行前已经暂存了需要提交的文件（使用 `git add` 或 `git commit -am` 会自动暂存所有已跟踪文件的修改）