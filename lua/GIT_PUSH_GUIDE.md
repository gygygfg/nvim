# Git Push 功能使用指南

## 问题诊断

根据检查，你当前处于 **分离头指针 (HEAD detached)** 状态。这意味着：
1. 你没有在任何一个分支上
2. 无法直接推送更改到 GitHub
3. 需要先切换到正常分支

## 解决方案

### 步骤 1: 修复分离头指针状态

使用新的快捷键 `<leader>gpf` (Git Push Fix)：
- 这个功能会检测你是否在分离头指针状态
- 如果是，它会提示你切换到现有分支或创建新分支
- 推荐切换到 `main` 分支

### 步骤 2: 提交当前更改

切换到正常分支后，你需要提交当前的更改：
1. 使用 `:Gwrite` 暂存文件
2. 使用 `:Git commit -m "提交信息"` 提交更改
3. 或者使用 fugitive 的界面操作

### 步骤 3: 检查推送状态

使用 `<leader>gps` (Git Push Status) 检查：
- 本地和远程分支的差异
- 有多少提交需要推送
- 推送权限是否正常

### 步骤 4: 执行推送

使用 `<leader>gpp` (Git Push with Rebase)：
- 自动执行 `git pull --rebase`
- 检查并处理冲突
- 执行 `git push`
- 提供详细的错误反馈

## 新增快捷键说明

| 快捷键 | 功能 | 描述 |
|--------|------|------|
| `<leader>gpf` | Git Push Fix | 修复分离头指针状态，切换到正常分支 |
| `<leader>gps` | Git Push Status | 检查 GitHub 推送状态和差异 |
| `<leader>gpp` | Git Push with Rebase | 使用 rebase 方式合并并推送（主要功能） |
| `<leader>gdc` | Git Diff Conflict | 查看并解决冲突 |

## 常见问题排查

### 1. GitHub 主页没显示更新
- 检查是否真的推送成功（使用 `<leader>gps`）
- 检查网络连接和权限
- 确认推送的目标分支正确

### 2. 推送失败
- 检查是否有未提交的更改
- 检查是否有合并冲突
- 检查 git 配置和远程仓库权限

### 3. 分离头指针状态
- 这是最常见的问题
- 使用 `<leader>gpf` 自动修复
- 或者手动执行 `git checkout main`

## 手动修复命令

如果快捷键不工作，可以手动执行：

```bash
# 1. 切换到主分支
git checkout main

# 2. 提交当前更改
git add .
git commit -m "提交说明"

# 3. 拉取最新代码
git pull --rebase origin main

# 4. 推送到 GitHub
git push origin main
```

## 测试脚本

我创建了一个测试脚本 `test_git_push.lua`，你可以加载它来检查当前状态：

```lua
:luafile test_git_push.lua
```

这个脚本会显示：
- 当前分支状态
- 远程仓库配置
- 推送权限测试
- 模拟推送过程

## 下一步建议

1. **立即执行**: 使用 `<leader>gpf` 修复分离头指针状态
2. **提交更改**: 提交你对 `keymaps.lua` 的修改
3. **测试推送**: 使用 `<leader>gps` 检查状态，然后 `<leader>gpp` 推送
4. **验证结果**: 打开 GitHub 页面确认更新

如果还有问题，请告诉我具体的错误信息，我会帮你进一步调试。