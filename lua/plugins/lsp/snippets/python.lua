local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
  s("class", fmt([[
      class {}:
          def __init__(self{}):
              {}
    ]], { i(1, "ClassName"), i(2, ""), i(0) })),

  s("main", fmt([[
      def main():
          {}

    if __name__ == "__main__":
          main()
    ]], { i(0) })),
}
