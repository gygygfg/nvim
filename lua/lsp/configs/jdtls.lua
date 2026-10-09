-- Java 语言服务器配置（Eclipse JDT Language Server）
-- 说明：
--   - 该配置由 lsp/init.lua 通过 vim.lsp.start 启动（use_lspconfig = false）
--   - jdtls 由 mason 安装，本文件在运行时探测 mason 安装目录并拼装完整启动命令，
--     以便稳定控制 workspace(-data)、configuration 目录与 Lombok(-javaagent)
--   - 格式化交由 conform.nvim 的 google-java-format，故关闭 jdtls 自带格式化

-- mason 数据目录
local function mason_packages_dir()
  return vim.fn.stdpath("data") .. "/mason/packages"
end

-- 简单的字符串哈希，用于为每个项目生成稳定的 workspace 目录名
local function hash_string(str)
  local h = 5381
  for i = 1, #str do
    h = (h * 33 + str:byte(i)) % 2147483647
  end
  return string.format("%08x", h)
end

-- Eclipse workspace 损坏特征（出现在 .metadata/.log 的崩溃堆栈中）。
-- 一旦命中，说明该项目的 workspace 状态树已损坏，jdtls 每次启动都会卡在
-- SaveManager.restore 而无法完成 initialize（表现为“没有激活的 LSP 服务”）。
-- 注意：workspace 目录名 = hash(项目根)，是确定性的，故损坏是“粘性”的——
-- 不重置的话每次打开同一项目都会复用坏缓存并复现。
local CORRUPTION_MARKERS = {
  "asBackwardDelta",
  "NoDataDeltaNode",
  "DeltaDataTree.reroot",
  "ElementTree.immutable",
}

-- 启动前自愈：若检测到 workspace 损坏，则删除整个 workspace 目录，
-- 让 jdtls 下次以全新状态重建（代价仅为一次重新索引）。
local function heal_corrupt_workspace(workspace)
  local log = workspace .. "/.metadata/.log"
  if vim.fn.filereadable(log) ~= 1 then
    return
  end
  local ok, lines = pcall(vim.fn.readfile, log)
  if not ok or type(lines) ~= "table" then
    return
  end
  for _, line in ipairs(lines) do
    for _, marker in ipairs(CORRUPTION_MARKERS) do
      if line:find(marker, 1, true) then
        vim.notify("[LSP] 检测到 jdtls workspace 损坏，已重置: " .. workspace, vim.log.levels.WARN)
        vim.fn.delete(workspace, "rf")
        return
      end
    end
  end
end

-- 向上查找项目根目录
-- 优先从当前打开文件所在目录出发（避免受 Neovim 启动目录 cwd 影响），
-- 找不到再回退到 cwd。
local function find_root()
  local patterns = {
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
    "mvnw",
    "gradlew",
    -- Eclipse/JDT 项目标记（无构建工具时的源码根配置）
    ".project",
    ".classpath",
    ".git",
    "WORKSPACE",
    "WORKSPACE.bazel",
  }

  -- 候选起点：当前文件所在目录 -> cwd
  local roots = {}
  local name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  if name ~= "" then
    roots[#roots + 1] = vim.fs.dirname(name)
  end
  roots[#roots + 1] = vim.fn.getcwd()

  for _, path in ipairs(roots) do
    local found = vim.fs.find(patterns, { upward = true, path = path })[1]
    if found then
      return vim.fs.dirname(found)
    end
  end
  return vim.fn.getcwd()
end

-- 探测 jdtls 安装位置（launcher jar、config 目录、lombok jar）
local function detect_jdtls()
  local base = mason_packages_dir() .. "/jdtls"
  local info = { base = base }

  -- launcher jar
  local launchers = vim.fn.glob(base .. "/plugins/org.eclipse.equinox.launcher_*.jar", true, true)
  info.launcher = launchers[1]

  -- configuration 目录（mason 在包内提供 config/，静态指向 config_linux 等）
  local config_linux = base .. "/config_linux"
  local config_dir = base .. "/config"
  if vim.fn.isdirectory(config_linux) == 1 then
    info.config = config_linux
  elseif vim.fn.isdirectory(config_dir) == 1 then
    info.config = config_dir
  end

  -- lombok jar（mason 安装到 share/jdtls/ 或包根目录）
  local candidates = {
    (vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")) .. "/share/jdtls/lombok.jar",
    base .. "/lombok.jar",
    base .. "/share/jdtls/lombok.jar",
  }
  for _, p in ipairs(candidates) do
    if vim.fn.filereadable(p) == 1 then
      info.lombok = p
      break
    end
  end

  return info
end

-- 构建 jdtls 启动命令
local function build_cmd()
  local info = detect_jdtls()

  -- 找不到 mason 的 jdtls 时，回退到 PATH 中的 jdtls 包装脚本
  if not info.launcher then
    return { "jdtls" }
  end

  local root = find_root()
  local workspace = vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. hash_string(root)
  -- 若上一次运行留下损坏的 workspace，启动前先重置，避免 jdtls 卡在
  -- SaveManager.restore 而永远无法附着（详见 heal_corrupt_workspace）。
  heal_corrupt_workspace(workspace)
  vim.fn.mkdir(workspace, "p")

  local cmd = {
    "java",
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx1g",
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",
  }

  -- Lombok：加载 javaagent（若可用）
  if info.lombok then
    vim.list_extend(cmd, { ("-javaagent:%s"):format(info.lombok) })
  end

  vim.list_extend(cmd, {
    "-jar",
    info.launcher,
    "-configuration",
    info.config,
    "-data",
    workspace,
  })

  return cmd
end

-- Neovim 0.12：cmd 为函数时必须返回 RPC client，而不是命令表。
-- 用 vim.lsp.rpc.start 包装动态构建的启动命令，保持 workspace/root 每次启动时计算。
local function cmd_factory(dispatchers, cfg)
  return vim.lsp.rpc.start(build_cmd(), dispatchers, {
    cwd = cfg and cfg.cmd_cwd or nil,
    env = cfg and cfg.cmd_env or nil,
    detached = cfg and cfg.detached or nil,
  })
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
-- jdtls 需要 utf-16 偏移编码，避免多字节字符定位错乱
capabilities.offsetEncoding = { "utf-16" }

return {
  name = "jdtls",
  cmd = cmd_factory,
  filetypes = { "java" },
  -- Neovim 0.12：函数式 root_dir 需为 (bufnr, on_dir) 回调签名，
  -- 而本框架通过 vim.lsp.start() 直接启动，不会调用该回调，
  -- 会把 root_dir 原样当成 Funcref（导致 checkhealth 报 E729）。
  -- 改用静态 root_markers：框架已透传 _root_markers，core 会解析为字符串 root。
  root_markers = {
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
    "mvnw",
    "gradlew",
    -- Eclipse/JDT 项目标记（无构建工具时的源码根配置）
    ".project",
    ".classpath",
    ".git",
    "WORKSPACE",
    "WORKSPACE.bazel",
  },
  capabilities = capabilities,
  init_options = {
    -- 由 DAP 插件在启动前注入 java-debug/java-test 的 bundles
    bundles = {},
  },
  settings = {
    java = {
      -- 关闭 jdtls 自带格式化，统一交给 conform.nvim (google-java-format)
      format = { enabled = false },
      signatureHelp = { enabled = true },
      completion = {
        favoriteStaticMembers = {
          "org.junit.Assert.*",
          "org.junit.jupiter.api.Assertions.*",
          "org.mockito.Mockito.*",
        },
        maxResults = 50,
        matchCase = "smart",
        postfix = { enabled = true },
      },
      -- 修改 pom/gradle 后提示更新配置
      configuration = {
        updateBuildConfiguration = "interactive",
      },
      referencesCodeLens = { enabled = false },
      implementationsCodeLens = { enabled = false },
      -- 关闭不必要的遥测/提示
      telemetry = { enabled = false },
    },
  },
}
