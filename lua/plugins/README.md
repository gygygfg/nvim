# 插件配置目录

此目录包含 Neovim 插件的配置模块。每个插件都有一个独立的 Lua 配置文件，便于管理和维护。

## 📁 目录结构

```
lua/plugins/
├── README.md              # 本文件
├── lastplace.lua          # 光标位置记忆插件
├── web-devicons.lua       # 文件图标插件
├── platformio.lua         # PlatformIO 支持
├── vim-translator.lua     # 翻译插件
├── lualine.lua           # 状态栏插件
└── ...                    # 其他插件配置
```

## 🎯 设计理念

### 模块化配置
每个插件都有独立的配置文件，包含：
- 插件声明和设置
- 快捷键映射
- 自定义命令
- 插件特定配置

### 按需加载
使用 lazy.nvim 的按需加载特性：
- **事件驱动**: 在特定事件触发时加载插件
- **命令驱动**: 执行特定命令时加载插件
- **文件类型**: 打开特定文件类型时加载插件

## 📝 创建新插件配置

### 基本模板

```lua
-- lua/plugins/example.lua
return {
  "作者/插件名",
  -- 插件版本
  version = "*",  -- 使用最新版本
  -- 或指定版本
  -- version = "~> 1.0.0",
  
  -- 依赖项
  dependencies = {
    "其他/依赖插件",
  },
  
  -- 事件触发加载
  event = "VeryLazy",  -- 延迟加载
  
  -- 或指定具体事件
  -- event = { "BufReadPre", "BufNewFile" },
  
  -- 或命令触发
  -- cmd = { "ExampleCommand" },
  
  -- 或文件类型触发
  -- ft = { "python", "lua" },
  
  -- 插件配置
  config = function()
    require("插件模块").setup({
      -- 插件配置选项
      option1 = true,
      option2 = "value",
    })
    
    -- 可选：添加快捷键
    vim.keymap.set("n", "<leader>ex", "<cmd>ExampleCommand<CR>", { desc = "执行示例命令" })
  end,
  
  -- 可选：插件加载前的设置
  init = function()
    -- 在插件加载前执行的代码
    vim.g.example_global_var = true
  end,
}
```

### 常用配置模式

#### 1. 基础插件配置
```lua
return {
  "user/plugin",
  config = function()
    require("plugin").setup({
      -- 配置选项
    })
  end,
}
```

#### 2. 带依赖的插件
```lua
return {
  "user/main-plugin",
  dependencies = {
    "user/dependency1",
    "user/dependency2",
  },
  config = function()
    -- 配置代码
  end,
}
```

#### 3. 条件加载插件
```lua
return {
  "user/conditional-plugin",
  -- 只在特定条件下加载
  cond = function()
    return vim.fn.executable("some_command") == 1
  end,
  config = function()
    -- 配置代码
  end,
}
```

## 🔧 现有插件说明

### lastplace.lua
- **功能**: 记住上次编辑位置
- **触发**: 自动加载
- **配置**: 简单的启用配置

### web-devicons.lua
- **功能**: 为文件浏览器提供图标
- **触发**: 自动加载
- **依赖**: nvim-tree/nvim-web-devicons

### platformio.lua
- **功能**: PlatformIO 嵌入式开发支持
- **触发**: 相关文件类型
- **配置**: 平台特定设置

### vim-translator.lua
- **功能**: 代码内翻译工具
- **触发**: 命令或快捷键
- **配置**: 翻译引擎和快捷键

### lualine.lua
- **功能**: 状态栏显示
- **触发**: 自动加载
- **配置**: 主题、组件和布局

## ⚙️ 配置管理

### 插件分组
插件可以按功能分组管理：

```lua
-- 在 init.lua 中
require("lazy").setup({
  -- 编辑增强插件组
  { import = "plugins.editing" },
  
  -- 外观插件组
  { import = "plugins.ui" },
  
  -- 开发工具插件组
  { import = "plugins.devtools" },
})
```

### 创建插件组目录
```
lua/plugins/
├── editing/     # 编辑增强插件
├── ui/          # 用户界面插件
└── devtools/    # 开发工具插件
```

## 🚀 最佳实践

1. **保持配置简洁**: 每个文件只配置一个插件
2. **使用描述性名称**: 文件名反映插件功能
3. **添加注释**: 说明配置选项的作用
4. **版本控制**: 指定插件版本以确保一致性
5. **错误处理**: 在配置中添加适当的错误处理

## 🔍 调试插件

### 检查插件状态
```vim
:Lazy status    " 查看插件状态
:Lazy log       " 查看插件日志
```

### 重新加载配置
```vim
:Lazy reload    " 重新加载所有插件
:Lazy reload plugin-name  " 重新加载特定插件
```

## 📚 相关资源

- [lazy.nvim 文档](https://github.com/folke/lazy.nvim#-installation)
- [Neovim 插件开发指南](https://github.com/nvim-lua/plenary.nvim)
- [Awesome Neovim](https://github.com/rockerBOO/awesome-neovim)

## 🤝 贡献指南

1. 添加新插件时，请创建独立的配置文件
2. 在配置文件中添加必要的注释
3. 测试插件功能是否正常
4. 更新相关文档（如有需要）