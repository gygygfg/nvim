return {
  "benlubas/molten-nvim",
  version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
  build = ":UpdateRemotePlugins",
  -- ft = { "python", "jupyter" }, -- 在打开python和jupyter文件时加载
  init = function()
    require('keymaps').molten()
    -- 确保Python环境已设置
    local success, _ = pcall(require, "python_venv")
    if success then
      require("python_venv").silent_setup()
    end

    -- this is an example, not a default. Please see the readme for more configuration options
    vim.g.molten_output_win_max_height = 12
    vim.g.molten_image_provider = "image.nvim"
    vim.g.molten_auto_open_output = true

    -- 设置ipynb文件的文件类型为julia
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      pattern = "*.ipynb",
      callback = function()
        vim.bo.filetype = "julia"
      end,
    })

    -- 添加Python依赖检查
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "python", "jupyter" },
      callback = function()
        vim.defer_fn(function()
          local python_path = vim.g.python3_host_prog
          if python_path then
            -- 检查Python模块
            local handle = io.popen(python_path .. " -c \"try:\n    import jupyter_client\n    print('jupyter-client: OK')\nexcept ImportError:\n    print('jupyter-client: MISSING')\" 2>/dev/null", "r")
            if handle then
              local result = handle:read("*l")
              handle:close()
              if result and result:match("MISSING") then
                vim.notify("molten-nvim: jupyter-client模块缺失，请运行: pip install jupyter-client", vim.log.levels.WARN)
              end
            end
          end
        end, 100)
      end,
      desc = "检查molten-nvim Python依赖"
    })
  end,
  dependencies = { "3rd/image.nvim" },
}
