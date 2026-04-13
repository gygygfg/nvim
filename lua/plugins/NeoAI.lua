vim.opt.packpath:append("/root/NeoAI")

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local ok, neoai = pcall(require, "NeoAI")
    if ok and type(neoai) == "table" and type(neoai.setup) == "function" then
      neoai.setup()
    else
      vim.notify("NeoAI 加载失败")
    end
  end,
})
