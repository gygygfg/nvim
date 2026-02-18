local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local rep = require("luasnip.extras").rep
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("c", {
  s("fori", fmt([[
    for (int {} = {}; {} < {}; {}++) {{
        {}
    }}
  ]], {
    i(1, "i"),  -- 变量名
    i(2, "0"),  -- 初始值
    rep(1),     -- 同步变量名
    i(3, "10"), -- 终止值
    rep(1),     -- 再次同步变量名
    i(0)        -- 循环体
  }), {
    priority = 10000,
    description = "Formatted for loop"
  }),

  s("main", fmt([[
    #include <{}>

    int main(){{
      {}
      return 0;
    }}
  ]], {
    i(1, "stdio.h"), -- 函数头文件
    i(0)             -- 函数主体
  }), {
    priority = 10000,
    description = "Formatted main"
  })
})
