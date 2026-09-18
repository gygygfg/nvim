vim.pack.add({ gh("CRAG666/code_runner.nvim") })

-- ===========================================================================
-- Java 运行命令：自动识别 package 目录结构
--
-- 解决 "NoClassDefFoundError: Main (wrong name: com/example/app/Main)" 问题：
--   原配置 `java $fileNameWithoutExt` 会用「简单类名」运行，但类一旦声明了
--   package，JVM 要求使用「全限定类名」并且从包的根目录作为 classpath 运行。
--
-- 本函数会：
--   1. 解析源码中的 `package a.b.c;` 声明；
--   2. 从文件所在目录向上剥离与包名尾部同名的目录，推出「源码根目录」；
--   3. 用 `javac -d .classes` 编译，再用 `java -cp .classes a.b.c.Main` 运行。
--   未声明 package 时退化为默认包（同时也能正确处理）。
-- ===========================================================================
local function build_java_command()
  local path = vim.fn.expand("%:p")
  if path == "" or vim.bo.buftype ~= "" then
    return nil
  end

  local fname = vim.fn.fnamemodify(path, ":t:r") -- 类名（去掉扩展名）
  local fdir = vim.fn.fnamemodify(path, ":p:h")  -- 文件所在目录

  -- 1) 解析 package 声明
  local pkg = nil
  local ok, lines = pcall(vim.fn.readfile, path)
  if ok then
    for _, line in ipairs(lines) do
      local m = line:match("^%s*package%s+([%w_%.]+)%s*;")
      if m and m ~= "" then
        pkg = m
        break
      end
    end
  end

  -- 2) 计算源码根目录：从文件目录向上，剥离与包名尾部逐段同名的目录
  local root = fdir
  if pkg then
    local parts = vim.split(pkg, ".", { plain = true })
    local i = #parts
    while i >= 1 and vim.fn.fnamemodify(root, ":t") == parts[i] do
      local parent = vim.fn.fnamemodify(root, ":h")
      if parent == root then -- 已到文件系统根，停止
        break
      end
      root = parent
      i = i - 1
    end
  end

  local fqcn = pkg and (pkg .. "." .. fname) or fname
  local outdir = root .. "/.classes"

  -- 3) 编译到隐藏目录 .classes，再以全限定类名运行
  --    末尾的 $end 会被 code_runner 替换为空串，从而阻止它自动追加文件路径。
  return {
    "cd " .. vim.fn.shellescape(root) .. " &&",
    "javac -encoding UTF-8 -d "
      .. vim.fn.shellescape(outdir)
      .. " "
      .. vim.fn.shellescape(path)
      .. " &&",
    "java -cp " .. vim.fn.shellescape(outdir) .. " " .. fqcn .. " $end",
  }
end

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
    -- 导入虚拟环境检测模块
    local nvim_venv = require("core.python_venv")

    -- 初始化虚拟环境检测
    nvim_venv.setup()

    -- 获取当前Python路径
    local python_info = nvim_venv.get_python_info()
    local python_cmd = "python3 -u"

    if not python_info.error then
      python_cmd = python_info.path .. " -u"
    end

    require("code_runner").setup({
      filetype = {
        java = build_java_command,
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
          "rm $fileNameWithoutExt",
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
})
