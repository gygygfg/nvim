-- lua/plugins/treesitter.lua
-- 初始化包管理器

vim.pack.add({
    -- 安装 plenary.nvim (nvim-treesitter 的依赖)
    gh("nvim-lua/plenary.nvim"),
    -- 安装 nvim-treesitter
    {
        src = "https://github.com/nvim-treesitter/nvim-treesitter",
        run = ":TSUpdate",
    },
    -- 安装 nvim-treesitter-textobjects (可选扩展)
    {
        src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    },
    -- 安装 rainbow-delimiters.nvim (nvim-ts-rainbow2 的现代替代品)
    {
        src = "https://github.com/HiPhish/rainbow-delimiters.nvim",
    },
    -- 安装 nvim-ts-context-commentstring (可选扩展)
    {
        src = "https://github.com/JoosepAlviste/nvim-ts-context-commentstring",
    },
})

local function setup()
  require("nvim-treesitter.configs").setup({
    -- 基础配置
    ensure_installed = {
      -- 核心语言
      "c",
      "cpp",
      "lua",
      "vim",
      "vimdoc",
      -- 前端开发
      "javascript",
      "typescript",
      "html",
      "css",
      "json",
      "yaml",
      -- 后端开发
      "python",
      "java",
      "go",
      "rust",
      "bash",
      "markdown",
      "markdown_inline",
    },

    -- 安装选项
    sync_install = false, -- 异步安装（推荐）
    auto_install = true, -- 自动检测并安装缺失的解析器

    -- 高亮配置
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false, -- 禁用传统高亮
      disable = function(lang, buf)
        -- 对大文件禁用 treesitter 高亮以提升性能
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
          return true
        end
      end,
    },

    -- 缩进配置
    indent = {
      enable = true,
      disable = { "python", "yaml" }, -- 某些语言可能需要禁用
    },

    -- 增量选择
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn", -- 进入增量选择模式
        node_incremental = "grn", -- 扩展选择范围
        scope_incremental = "grc", -- 扩展到整个作用域
        node_decremental = "grm", -- 缩小选择范围
      },
    },

    -- 代码折叠
    fold = {
      enable = true,
      disable = { "markdown" }, -- 某些语言可能需要禁用折叠
    },

    -- 文本对象（需要 nvim-treesitter-textobjects 插件）
    textobjects = {
      enable = true,
      select = {
        enable = true,
        keymaps = {
          ["af"] = "@function.outer", -- 选择整个函数
          ["if"] = "@function.inner", -- 选择函数体
          ["ac"] = "@class.outer", -- 选择整个类
          ["ic"] = "@class.inner", -- 选择类体
        },
      },
    },

    -- 彩虹括号（需要 rainbow-delimiters.nvim 插件）
    -- rainbow-delimiters.nvim 使用独立的 setup 函数，不在 treesitter configs 中配置

    -- 上下文注释（需要 nvim-ts-context-commentstring 插件）
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
    },
  })

  -- 启用代码折叠
  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  vim.wo.foldlevel = 99 -- 默认展开所有折叠

  -- 彩虹括号配置 (rainbow-delimiters.nvim)
  -- 使用新的 API 替代 vim.g.rainbow_active
  local status_ok, rainbow = pcall(require, "rainbow-delimiters.setup")
  if status_ok then
    rainbow.enable()
  end
end

-- 创建用户命令
vim.api.nvim_create_user_command("LoadTreesitter", function()
  setup()
  vim.notify("nvim-treesitter loaded!", vim.log.levels.INFO)
end, {})

-- 按需加载的自动命令
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.lua", "*.py", "*.js", "*.ts", "*.rs", "*.go", "*.cpp", "*.c", "*.java" },
  callback = function(args)
    local buf = args.buf

    -- 检查 treesitter 是否已加载
    local loaded = false
    for _, plugin in ipairs(vim.fn.getcompletion("nvim-treesitter", "packadd")) do
      if vim.fn.getwinvar(0, "&rtp"):find(plugin, 1, true) then
        loaded = true
        break
      end
    end

    if not loaded then
      setup()
      vim.notify(
        "nvim-treesitter loaded for " .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t"),
        vim.log.levels.INFO
      )
    end
  end,
})

-- 启动时自动加载（可选）
--[[ vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    -- 可以在这里添加条件，比如只对特定文件类型加载
    local filetype = vim.bo.filetype
    local treesitter_filetypes = {
      "lua",
      "python",
      "javascript",
      "typescript",
      "rust",
      "go",
      "cpp",
      "c",
      "java",
      "html",
      "css",
      "vim",
    }

    for _, ft in ipairs(treesitter_filetypes) do
      if filetype == ft then
        setup()
        return
      end
    end
  end,
})
 ]]
return M
