return {
  "CRAG666/code_runner.nvim",
  config = function()
    -- 导入虚拟环境检测模块
    local nvim_venv = require('python_venv')

    -- 初始化虚拟环境检测
    nvim_venv.setup()

    -- 获取当前Python路径
    local python_info = nvim_venv.get_python_info()
    local python_cmd = "python3 -u"

    if not python_info.error then
      python_cmd = python_info.path .. " -u"
    end

    require('code_runner').setup({
      filetype = {
        java = {
          "cd $dir &&",
          "javac $fileName &&",
          "java $fileNameWithoutExt"
        },
        python = python_cmd,
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
      -- 添加Python运行前的虚拟环境检测
      before_run = function(filetype, filename)
        if filetype == "python" then
          -- 重新检测虚拟环境，确保使用正确的Python路径
          nvim_venv.silent_setup()
          local info = nvim_venv.get_python_info()
          if not info.error then
            vim.notify(string.format("使用Python: %s", info.path), vim.log.levels.INFO, { title = "Code Runner" })
          end
        end
      end,
    })
  end,
  cmd = 'RunCode',
  init = require('keymaps').code_runner(),
}
