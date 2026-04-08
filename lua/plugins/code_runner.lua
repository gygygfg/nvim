vim.pack.add({ gh("CRAG666/code_runner.nvim") })

vim.api.nvim_create_autocmd("BufRead", {
  once = true,
  callback = function()
    vim.keymap.set("n", "<leader>rr", ":RunCode<CR>a", { noremap = true, silent = false })
    vim.keymap.set("n", "<leader>rf", ":RunFile<CR>a", { noremap = true, silent = false })
    vim.keymap.set("n", "<leader>rft", ":RunFile tab<CR>a", { noremap = true, silent = false })
    vim.keymap.set("n", "<leader>rp", ":RunProject<CR>a", { noremap = true, silent = false })
    vim.keymap.set("n", "<leader>rc", ":RunClose<CR>a", { noremap = true, silent = false })
    vim.keymap.set("n", "<leader>crf", ":CRFiletype<CR>a", { noremap = true, silent = false })
    vim.keymap.set("n", "<leader>crp", ":CRProjects<CR>a", { noremap = true, silent = false })
    require("code_runner").setup({
      filetype = {
        java = {
          "cd $dir &&",
          "javac $fileName &&",
          "java $fileNameWithoutExt",
        },
        python = "python3 -u",
        typescript = "deno run",
        javascript = "node",
        rust = {
          "cd $dir &&",
          "rustc $fileName &&",
          "$dir/$fileNameWithoutExt",
        },
        c = "cd $dir && gcc $fileName -o /tmp/$fileNameWithoutExt && /tmp/$fileNameWithoutExt",
      },
    })
  end,
})
