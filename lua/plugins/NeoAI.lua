vim.opt.packpath:append("/root/NeoAI")

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    require("NeoAI").setup({
      session = {
        auto_naming = false, -- 关闭自动命名
      },
      ai = {
        scenarios = {
          chat = {
            -- deepseek-v4-flash
            -- deepseek-v4-pro
            model_name = "deepseek-v4-pro",
          },
        },
      },
    })
  end,
})
