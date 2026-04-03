-- lua/config/luasnip.lua
-- @load_event LSP_READY
-- LuaSnip 配置

vim.pack.add({
  { src = "https://github.com/L3MON4D3/LuaSnip" },
})

vim.api.nvim_create_autocmd('VimEnter', {
	    callback = function()
require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_snipmate").lazy_load()

-- 自定义代码片段
local ls = require("luasnip")

-- 添加一些常用片段
ls.add_snippets("all", {
  ls.parser.parse_snippet("todo", "TODO: $1"),
  ls.parser.parse_snippet("fixme", "FIXME: $1"),
  ls.parser.parse_snippet("note", "NOTE: $1"),
})

ls.add_snippets("lua", {
  ls.parser.parse_snippet("req", "local $1 = require(\"$1\")"),
  ls.parser.parse_snippet("func", "function $1($2)\n  $3\nend"),
})
end
})
