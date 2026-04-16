vim.opt.packpath:append("/root/NeoAI")

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    require("NeoAI").setup()
  end,
})
