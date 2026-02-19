-- Git 插件使用示例
-- 这个文件展示了如何在主配置中使用 git/init.lua

-- 方法1: 直接引入插件配置
-- 在 lazy.nvim 或 packer.nvim 的插件配置中：
-- {
--   import = "git.init",  -- 引入 git 插件配置
-- },

-- 方法2: 作为模块使用
local git_plugins = require("git.init")

-- 初始化 Git 插件
git_plugins.setup()

-- 获取 Git 相关快捷键说明
local git_keymaps = git_plugins.get_keymaps()
print("Git 相关快捷键:")
for _, keymap in ipairs(git_keymaps) do
  print(string.format("  %s: %s", keymap.lhs, keymap.desc))
end

-- 方法3: 在现有的插件管理器中整合
-- 如果你的项目使用 lazy.nvim，可以这样配置：
-- local plugins = {
--   -- 其他插件...
--   
--   -- Git 相关插件
--   { import = "git.init" },
--   
--   -- 其他插件...
-- }
-- 
-- require("lazy").setup(plugins)

-- 方法4: 条件加载
-- 可以根据条件决定是否加载 Git 插件
local load_git_plugins = true  -- 可以从配置文件中读取

if load_git_plugins then
  -- 加载 Git 插件
  require("lazy").setup({
    { import = "git.init" },
    -- 其他插件...
  })
end

-- 方法5: 自定义配置
-- 如果你想覆盖 git/init.lua 中的某些配置：
-- local custom_git_config = {
--   {
--     "tpope/vim-fugitive",
--     lazy = true,  -- 覆盖原来的 lazy = false
--     event = "BufEnter",  -- 添加自定义事件
--     config = function()
--       -- 可以在这里添加自定义配置
--       require("git.init").setup()
--     end
--   }
-- }

print("\nGit 插件配置加载完成!")
print("可用命令:")
print("  :Gstatus - 查看 Git 状态")
print("  :Gcommit - 提交更改")
print("  :Gpush   - 推送更改")
print("  :Gpull   - 拉取更改")

print("\n可用快捷键:")
print("  <leader>gc - Git 提交")
print("  <leader>fc - Git 提交历史")
print("  <leader>fs - Git 状态")
print("  <leader>fb - Git 分支")