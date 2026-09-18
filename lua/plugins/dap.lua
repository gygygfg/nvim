-- lua/plugins/dap.lua
-- 调试（DAP）配置：nvim-dap + nvim-dap-ui，内置 Java(jdtls) 调试支持

vim.pack.add({
  gh("mfussenegger/nvim-dap"),
  gh("rcarriga/nvim-dap-ui"),
  gh("nvim-neotest/nvim-nio"),
})

local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  vim.notify("nvim-dap 未安装，跳过 DAP 配置", vim.log.levels.WARN)
  return
end

-- 加载依赖
pcall(require, "nvim-nio")
local ok_dapui, dapui = pcall(require, "dapui")
if ok_dapui then
  dapui.setup({
    icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
    layouts = {
      {
        elements = {
          { id = "scopes", size = 0.40 },
          { id = "breakpoints", size = 0.20 },
          { id = "stacks", size = 0.20 },
          { id = "watches", size = 0.20 },
        },
        size = 40,
        position = "left",
      },
      {
        elements = {
          { id = "repl", size = 0.5 },
          { id = "console", size = 0.5 },
        },
        size = 12,
        position = "bottom",
      },
    },
    floating = { border = "rounded" },
  })
end

-- 调试 UI 自动开关
if ok_dapui then
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
end

-- ============================================================
-- Java 调试适配器（java-debug-adapter）
-- ============================================================
local function mason_packages_dir()
  return vim.fn.stdpath("data") .. "/mason/packages"
end

-- java-debug-adapter 以 server 模式启动：随机/指定端口，等待 IDE 连接
local function java_debug_adapter()
  local jar = vim.fn.glob(
    mason_packages_dir() .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
    true,
    true
  )[1]
  if not jar then
    vim.notify("java-debug-adapter 尚未就绪（将自动安装，或运行 :MasonInstall java-debug-adapter）", vim.log.levels.WARN)
    return nil
  end
  return { type = "server", port = "${port}", executable = { command = "java", args = { "-jar", jar, "${port}" } } }
end

local adapter = java_debug_adapter()
if adapter then
  dap.adapters.java = adapter
end

-- Java 调试配置
dap.configurations.java = {
  {
    type = "java",
    request = "launch",
    name = "Launch Java (选择主类)",
    mainClass = function()
      -- 尝试从当前文件推断主类名
      local bufnr = vim.api.nvim_get_current_buf()
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local package = ""
      for _, line in ipairs(lines) do
        local p = line:match("^%s*package%s+([%w%.]+)%s*;")
        if p then
          package = p .. "."
          break
        end
      end
      for _, line in ipairs(lines) do
        local class = line:match("^%s*(?:public%s+)?class%s+([%w_]+)")
        if class then
          return package .. class
        end
      end
      return vim.fn.expand("%:t:r")
    end,
    cwd = "${workspaceFolder}",
    console = "integratedTerminal",
  },
  {
    type = "java",
    request = "attach",
    name = "Attach to Remote JVM (5005)",
    hostName = "127.0.0.1",
    port = 5005,
  },
}

-- ============================================================
-- 键位（<leader>d 前缀此前未被占用）
-- ============================================================
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map("n", "<F5>", function()
  dap.continue()
end, vim.tbl_extend("force", opts, { desc = "DAP: 继续/启动" }))
map("n", "<F10>", function()
  dap.step_over()
end, vim.tbl_extend("force", opts, { desc = "DAP: 单步跳过" }))
map("n", "<F11>", function()
  dap.step_into()
end, vim.tbl_extend("force", opts, { desc = "DAP: 单步进入" }))
map("n", "<F12>", function()
  dap.step_out()
end, vim.tbl_extend("force", opts, { desc = "DAP: 单步跳出" }))
map("n", "<leader>db", function()
  dap.toggle_breakpoint()
end, vim.tbl_extend("force", opts, { desc = "DAP: 切换断点" }))
map("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("条件断点: "))
end, vim.tbl_extend("force", opts, { desc = "DAP: 条件断点" }))
map("n", "<leader>du", function()
  if ok_dapui then
    dapui.toggle()
  end
end, vim.tbl_extend("force", opts, { desc = "DAP: 切换调试 UI" }))
map("n", "<leader>dt", function()
  dap.terminate()
end, vim.tbl_extend("force", opts, { desc = "DAP: 终止调试" }))

-- ============================================================
-- Mason 依赖自愈：检查并自动安装 java-debug-adapter / java-test
-- ============================================================
vim.defer_fn(function()
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return
  end

  local names = { "java-debug-adapter", "java-test" }
  local missing = {}
  for _, name in ipairs(names) do
    local okpkg, pkg = pcall(registry.get_package, name)
    if not (okpkg and pkg:is_installed()) then
      table.insert(missing, name)
    end
  end

  if #missing == 0 then
    return
  end

  vim.notify(
    "Java 调试依赖缺失，正在自动安装: " .. table.concat(missing, ", "),
    vim.log.levels.INFO
  )

  -- 触发安装（不同 mason 版本 install() 是否接管回调不一，用 pcall 包裹兼容）
  for _, name in ipairs(missing) do
    local okpkg, pkg = pcall(registry.get_package, name)
    if okpkg and pkg then
      pcall(function()
        pkg:install({}, function() end)
      end)
    end
  end

  -- 轮询校验安装结果（约 15s 一次，最多 8 次）
  local tries = 0
  local max_tries = 8
  local function verify()
    tries = tries + 1
    local still_missing = {}
    for _, name in ipairs(names) do
      local okpkg, pkg = pcall(registry.get_package, name)
      if not (okpkg and pkg:is_installed()) then
        table.insert(still_missing, name)
      end
    end
    if #still_missing == 0 then
      vim.notify("Java 调试依赖安装完成: " .. table.concat(names, ", "), vim.log.levels.INFO)
      return
    end
    if tries >= max_tries then
      vim.notify(
        "Java 调试依赖仍未安装完成: "
          .. table.concat(still_missing, ", ")
          .. "\n可手动运行 :MasonInstall "
          .. table.concat(still_missing, " "),
        vim.log.levels.WARN
      )
      return
    end
    vim.defer_fn(verify, 15000)
  end
  vim.defer_fn(verify, 15000)
end, 2000)
