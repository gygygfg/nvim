local opt = vim.opt

-- 界面设置
opt.number = true -- 显示行号
opt.relativenumber = true -- 相对行号
opt.signcolumn = "yes" -- 总是显示标记列
opt.cursorline = true -- 高亮当前行
opt.termguicolors = true -- 真彩色支持

-- 编辑行为
opt.expandtab = true -- Tab转空格
opt.tabstop = 4 -- Tab宽度
opt.shiftwidth = 4 -- 自动缩进宽度
-- opt.smartindent = true     -- 智能缩进
opt.wrap = false -- 不自动换行

-- 搜索
opt.ignorecase = true -- 忽略大小写
opt.smartcase = true -- 智能大小写
opt.hlsearch = true -- 高亮搜索结果
opt.incsearch = true -- 增量搜索

-- 其他
opt.mouse = "a" -- 启用鼠标
opt.clipboard = "unnamedplus" -- 系统剪贴板
opt.swapfile = false -- 不创建交换文件
opt.undofile = true -- 持久化撤销

-- 从 local_conf.lua 迁移的选项
-- 不要全局启用粘贴模式，它会禁用补全功能
-- 改为使用自动命令在需要时启用粘贴模式
opt.paste = false

-- 默认缩进设置
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

-- 主题设置
-- 支持 24 位彩色
opt.termguicolors = true

-- 启用折叠
opt.foldenable = true
opt.foldmethod = "indent"
-- 最小的自动折叠行数
opt.foldminlines = 2

-- 系统剪贴板
-- opt.clipboard:append("unnamedplus")

-- 搜索
opt.ignorecase = true
opt.smartcase = true

-- 确保状态行显示
opt.laststatus = 2 -- 总是显示状态行
opt.showmode = true -- 显示当前模式
opt.ruler = true -- 显示光标位置

-- 设置格式化选项（逐个设置）
opt.formatoptions:remove("a") -- 禁用自动格式化
opt.formatoptions:remove("t") -- 不要自动格式化文本
opt.formatoptions:append("c") -- 自动格式化注释
opt.formatoptions:append("q") -- 允许使用 gq 格式化注释
opt.formatoptions:remove("o") -- 不要在使用 o 或 O 时自动插入注释
opt.formatoptions:remove("r") -- 不要在回车时继续注释
opt.formatoptions:append("n") -- 识别编号列表
opt.formatoptions:append("j") -- 在合适的地方删除注释前缀

-- 禁用写入备份提示
opt.writebackup = false
opt.backup = false
