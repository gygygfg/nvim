# Git 配置文件夹

这个文件夹包含了所有与Git相关的配置文件和文档。

## 文件说明

### 1. fugitive.lua
- **描述**: vim-fugitive插件的配置文件
- **功能**:
- 配置vim-fugitive插件的行为
- 设置git可执行文件路径
- 自定义fugitive缓冲区的外观和行为
- 配置自动关闭fugitive缓冲区的功能

### 2. telescope.lua
- **描述**: Telescope插件中Git相关功能的配置文件
- **功能**:
- 配置Git提交历史的查看和操作
- 设置Git状态和分支的查看快捷键
- 自定义Git提交历史窗口的行为
- 配置Git重置（reset）和检出（checkout）的快捷键

### 3. test-git-commit.md
- **描述**: Git commit快捷键的使用说明文档
- **内容**:
- `<leader>gc`快捷键的功能说明
- 普通模式和可视模式下的使用方法
- 配置位置和注意事项
- 测试方法

## Git相关快捷键

### fugitive.lua 配置的快捷键
- `<leader>gc` - 执行git commit -am并输入提交信息

### telescope.lua 配置的快捷键
- `<leader>fc` - 查看Git提交历史
- `<leader>fs` - 查看Git状态
- `<leader>fb` - 查看Git分支

### Git提交历史窗口中的快捷键
- `<Enter>` - 硬重置（git reset --hard）到选中的提交
- `<c-r>m` - 混合重置（git reset --mixed）
- `<c-r>s` - 软重置（git reset --soft）
- `<c-r>h` - 硬重置（git reset --hard）
- `<c-c>` - 检出（git checkout）到选中的提交

## 插件管理

### init.lua
- **描述**: Git相关插件的统一管理文件
- **功能**:
- 统一管理所有Git相关插件的lazy加载配置
- 整合vim-fugitive和telescope的Git功能配置
- 提供模块化的插件管理接口
- 支持可选的Git插件扩展

### 插件列表
1. **vim-fugitive** (`tpope/vim-fugitive`)
  - 完整的Git集成插件
- 启动时立即加载 (`lazy = false`)

2. **telescope.nvim** (`nvim-telescope/telescope.nvim`)
  - 模糊查找插件，包含Git功能
  - 延迟加载：当使用Git相关命令时加载
  - 包含Git提交历史、状态、分支查看功能

### 模块接口
  ```lua
  -- 在Neovim配置中引入
  local git_plugins = require("git.init")

  -- 初始化Git插件
git_plugins.setup()

  -- 获取Git相关快捷键说明
local git_keymaps = git_plugins.get_keymaps()
  ```

## 使用说明

### 在主配置中引入

#### 方法1: 直接引入（推荐）
  ```lua
  -- 在你的主插件配置文件（如 plugins.lua 或 init.lua）中：
  return {
    -- 其他插件配置...

      -- 引入 Git 插件配置
      { import = "git.init" },

      -- 其他插件配置...
  }
```

#### 方法2: 作为模块使用
```lua
-- 在 Neovim 的 init.lua 或配置文件中：
local git_plugins = require("git.init")

  -- 初始化 Git 插件
git_plugins.setup()

  -- 获取 Git 相关快捷键说明
local git_keymaps = git_plugins.get_keymaps()
  for _, keymap in ipairs(git_keymaps) do
  print(string.format("%s: %s", keymap.lhs, keymap.desc))
  end
  ```

### 文件说明

  1. **init.lua** - 主插件管理文件，整合所有 Git 插件配置
  2. **fugitive.lua** - vim-fugitive 的原始配置（保留供参考）
  3. **telescope.lua** - telescope 的原始配置（保留供参考）
  4. **test-git-commit.md** - Git commit 功能测试文档
  5. **example_usage.lua** - 使用示例文件
  6. **README.md** - 本说明文件

## 迁移说明

  所有Git相关的配置文件都已迁移到此文件夹中，包括：
  1. vim-fugitive插件的配置
  2. Telescope插件中的Git功能配置
  3. Git commit功能的测试文档
  4. 统一的插件管理文件 (init.lua)
5. 使用示例文件 (example_usage.lua)

  这样可以保持项目结构的整洁性，所有Git相关配置集中管理。
