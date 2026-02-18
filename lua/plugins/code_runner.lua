return {
  "CRAG666/code_runner.nvim",
  config = function()
    require('code_runner').setup({
      filetype = {
        java = {
          "cd $dir &&",
          "javac $fileName &&",
          "java $fileNameWithoutExt"
        },
        python = "python3 -u",
        typescript = "deno run",
        javascript = "node $fileName",
        rust = {
          -- "cd $dir &&",
          -- "rustc $fileName &&",
          -- "$dir/$fileNameWithoutExt"
          "cargo run &&",
          "echo",
        },
        c = {
          "gcc $fileName -o $fileNameWithoutExt -lm &&",
          "$dir/$fileNameWithoutExt &&",
          "rm $fileNameWithoutExt"
        },
      },
    })
  end,
  cmd = 'RunCode',
  init = require('keymaps').code_runner(),
}
