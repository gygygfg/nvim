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

-- 向上查找项目根目录
local function find_root()
  local patterns = {
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
    "mvnw",
    "gradlew",
    ".git",
    "WORKSPACE",
    "WORKSPACE.bazel",
  }
  local found = vim.fs.find(patterns, { upward = true, path = vim.fn.getcwd() })[1]
  if found then
    return vim.fs.dirname(found)
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
  root_dir = find_root,
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
