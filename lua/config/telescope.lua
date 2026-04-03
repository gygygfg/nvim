-- 搜索和导航插件配置
-- 配置 nvim-notify

vim.pack.add({
	-- plenary.nvim - Telescope 依赖
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	-- telescope.nvim - 模糊查找
	{ src = "https://github.com/nvim-telescope/telescope.nvim" },
	-- telescope-fzf-native.nvim - Telescope FZF 原生支持
	{ src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },
})

vim.api.nvim_create_autocmd('VimEnter', {
	    callback = function()
require("telescope").setup({
	-- 配置 telescope
	defaults = {
		mappings = {
			i = {
				["<C-j>"] = require("telescope.actions").move_selection_next,
				["<C-k>"] = require("telescope.actions").move_selection_previous,
				["<esc>"] = require("telescope.actions").close,
			},
		},
	},
	pickers = {
		find_files = {
			theme = "dropdown",
		},
		live_grep = {
			theme = "dropdown",
		},
	},
	extensions = {
		fzf = {
			fuzzy = true,
			override_generic_sorter = true,
			override_file_sorter = true,
			case_mode = "smart_case",
		},
	},
})

-- 加载 fzf 扩展
require("telescope").load_extension("fzf")

-- 设置快捷键
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", function()
	builtin.find_files()
end, { desc = "查找文件" })

vim.keymap.set("n", "<leader>fg", function()
	builtin.live_grep()
end, { desc = "实时搜索" })

vim.keymap.set("n", "<leader>fb", function()
	builtin.buffers()
end, { desc = "缓冲区" })

vim.keymap.set("n", "<leader>fh", function()
	builtin.help_tags()
end, { desc = "帮助标签" })
end
})
