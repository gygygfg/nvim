local opt = vim.opt

-- 不要全局启用粘贴模式，它会禁用补全功能
-- 改为使用自动命令在需要时启用粘贴模式
opt.paste = false

-- 显示行号
opt.number = true
-- 显示相对行号
opt.relativenumber = true
-- 自动换行
opt.wrap = false

-- 同时显示绝对行号和相对行号
-- opt.statusline = '%3n %=%m%w%h'  -- 注释掉这行，让lualine接管状态行

-- 默认缩进设置
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

-- 根据文件类型设置缩进
vim.api.nvim_create_autocmd("FileType", {
  -- 缩进2格的文件类型
  pattern = {
    "lua",
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "json",
    "css",
    "html",
    "xml",
    "yaml",
    "markdown",
    "sh",
    "bash",
    "zsh",
    "php",
    "ruby",
    "vim",
    "terraform",
    "hcl",
    "dockerfile",
    "yaml.docker-compose"
  },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.bo.shiftwidth = 2 -- 某些语言使用 2 空格缩进
    vim.bo.tabstop = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  -- 缩进4格的文件类型
  pattern = {
    "python",
    "java",
    "c",
    "cpp",
    "go",
    "rust",
    "swift",
    "kotlin",
    "scala",
    "cs",
    "dart",
    "perl",
    "fortran"
  },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.bo.shiftwidth = 4 -- 某些语言使用 2 空格缩进
    vim.bo.tabstop = 4
    vim.opt_local.expandtab = true
  end,
})

-- 缩进3格的文件类型
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "haskell",
    "puppet",
    "smarty"
  },
  callback = function()
    vim.opt_local.tabstop = 3
    vim.opt_local.shiftwidth = 3
    vim.opt_local.softtabstop = 3
    vim.bo.shiftwidth = 3 -- 某些语言使用 2 空格缩进
    vim.bo.tabstop = 3
    vim.opt_local.expandtab = true
  end,
})

-- 特殊文件类型设置
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "make" },
  callback = function()
    vim.opt_local.noexpandtab = true -- makefile 必须使用制表符
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- 保存时自动格式化
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local filetype = vim.bo.filetype
    local sensitive_filetypes = { "yaml", "python", "yml", "py", "dockerfile" } -- 缩进敏感的文件
    local is_sensitive = false
    for _, ft in ipairs(sensitive_filetypes) do
      if filetype == ft then
        is_sensitive = true
        break
      end
    end

    -- 检查是否有可用的LSP格式化功能
    local function has_lsp_formatting()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      for _, client in ipairs(clients) do
        if client.supports_method("textDocument/formatting") then
          return true
        end
      end
      return false
    end

    -- LSP格式化函数
    local function formatWithLSP(show_msg)
      local has_formatting = has_lsp_formatting()
      if has_formatting then
        -- 保存光标位置
        local save_cursor = vim.fn.getpos(".")

        -- 使用LSP格式化
        vim.lsp.buf.format({
          async = false, -- 同步格式化，确保在保存前完成
          filter = function(client)
            -- 只使用支持格式化的客户端
            return client.supports_method("textDocument/formatting")
          end
        })

        -- 恢复光标位置
        vim.fn.setpos(".", save_cursor)

        if show_msg then
          vim.defer_fn(function()
            vim.notify("已使用LSP格式化", vim.log.levels.INFO, {
              title = "格式化",
              timeout = 2000,
            })
          end, 100)
        end
        return true
      end
      return false
    end

    -- 原有的gg=G格式化函数
    local function formatWithGG(show_msg)
      if not is_sensitive then
        local save_cursor = vim.fn.getpos(".")
        vim.cmd("silent! normal! gg=G")
        vim.fn.setpos(".", save_cursor)
        if show_msg then
          vim.defer_fn(function()
            vim.notify("已使用 gg=G 格式化", vim.log.levels.INFO, {
              title = "格式化",
              timeout = 2000,
            })
          end, 100) -- 短暂延迟确保格式化完成
        end
      end
    end

    -- 优先使用LSP格式化，如果不可用则使用gg=G
    local lsp_success = formatWithLSP(true)
    if not lsp_success then
      formatWithGG(true)
    end
  end,
})

-- 可选：为特定文件类型添加额外的格式化设置
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  callback = function()
    -- 如果安装了 black，可以使用它来格式化 Python 代码
    if vim.fn.executable("black") == 1 then
      vim.opt_local.formatprg = "black -q - 2>/dev/null"
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact", "json", "css", "html" },
  callback = function()
    -- 如果安装了 prettier，可以使用它来格式化前端代码
    if vim.fn.executable("prettier") == 1 then
      vim.opt_local.formatprg = "prettier --stdin-filepath % 2>/dev/null"
    end
  end,
})

-- 设置格式化选项（逐个设置）
vim.opt.formatoptions:remove("a") -- 禁用自动格式化
vim.opt.formatoptions:remove("t") -- 不要自动格式化文本
vim.opt.formatoptions:append("c") -- 自动格式化注释
vim.opt.formatoptions:append("q") -- 允许使用 gq 格式化注释
vim.opt.formatoptions:remove("o") -- 不要在使用 o 或 O 时自动插入注释
vim.opt.formatoptions:remove("r") -- 不要在回车时继续注释
vim.opt.formatoptions:append("n") -- 识别编号列表
vim.opt.formatoptions:append("j") -- 在合适的地方删除注释前缀


-- 主题设置
-- 支持 24 位彩色
opt.termguicolors = true
-- 优先尝试 Monospaced 版本
-- vim.opt.guifont = "FiraCode Nerd Font Mono:h11"
-- 或者尝试
-- vim.opt.guifont = "Monaspace Argon NF:h11"
opt.background = white
opt.syntax = "on"
-- vim.cmd[[colorscheme delek]]

-- 启用折叠
opt.foldenable = true
opt.foldmethod = "indent"
-- 最小的自动折叠行数
opt.foldminlines = 1

-- 系统剪贴板
-- opt.clipboard:append("unnamedplus")

-- 搜索
opt.ignorecase = true
opt.smartcase = true
vim.api.nvim_create_autocmd('InsertEnter', {
  -- 检测剪贴板中的文本长度，如果很长则提示使用 paste 模式
  callback = function()
    local clipboard = vim.fn.getreg('+')
    if clipboard and #clipboard > 200 then  -- 超过200个字符
      vim.defer_fn(function()
        vim.notify('检测到大段文本，按 F2 可切换 paste 模式避免缩进问题', 
        vim.log.levels.INFO, { 
          title = '粘贴提示', 
          timeout = 3000 
        })
      end, 100)
    end
  end,
})

vim.api.nvim_create_user_command('Paste', function()
  -- 4. 提供简单的 :Paste 命令
  vim.o.paste = true
  vim.notify('已启用 paste 模式，粘贴完成后会自动关闭', 
  vim.log.levels.INFO, { 
    title = '粘贴模式', 
    timeout = 2000 
  })
  -- 插入模式离开后自动关闭 paste 模式
  vim.api.nvim_create_autocmd('InsertLeave', {
    once = true,
    callback = function()
      vim.o.paste = false
      vim.notify('已自动关闭 paste 模式', 
      vim.log.levels.INFO, { 
        title = '粘贴模式', 
        timeout = 1500 
      })
    end,
  })
end,{ desc = '启用 paste 模式进行粘贴' })

-- 确保状态行显示
vim.opt.laststatus = 2  -- 总是显示状态行
vim.opt.showmode = true  -- 显示当前模式
vim.opt.ruler = true     -- 显示光标位置


vim.diagnostic.config({
  -- 简化诊断提示
  virtual_text = { 
    enabled = false,  -- 禁用行内诊断提示
    prefix = "■" 
  }, 
  float = { 
    border = "none" 
  } 
})
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  -- 关闭悬浮文档（手机端不易触达）
  vim.lsp.handlers.hover, { border = "none" }
)

-- ==================== 全局配置更改提示禁用 ====================
-- 禁用所有配置更改检测提示，避免干扰

-- 设置全局变量，禁用配置更改提示
vim.g.disable_config_change_prompt = true
vim.g.silent_config_reload = true

-- 设置静默模式
vim.o.shortmess = vim.o.shortmess .. "s"  -- 添加静默标志

-- 全局拦截配置更改消息
local original_notify = vim.notify
vim.notify = function(msg, level, opts)
  -- 过滤掉配置更改相关的提示
  if type(msg) == "string" then
    -- 检查是否包含配置更改相关关键词
    local config_change_keywords = {
      "Config Change Detected",
      "Press ENTER or type command to continue",
      "Reloading",
      "配置已更改",
      "重新加载",
      "提交成功:"
    }

    for _, keyword in ipairs(config_change_keywords) do
      if string.find(msg, keyword) then
        -- 静默处理，不显示提示
        return
      end
    end
  end

  -- 调用原始的通知函数
  return original_notify(msg, level, opts)
end

-- 禁用所有插件配置更改提示
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyReload",
  callback = function()
    -- 静默处理 Lazy.nvim 的重载
    vim.cmd("silent! echo ''")
    vim.cmd("redraw")
  end,
  group = vim.api.nvim_create_augroup("GlobalSilentLazyReload", { clear = true })
})

-- 通用配置文件更改静默处理
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.lua",
  callback = function(args)
    local filename = vim.fn.fnamemodify(args.file, ":t")

    -- 检查是否是配置文件
    local config_files = {
      "codecompanion.lua",
      "local_conf.lua",
      "keymaps.lua",
      "nvim_venv.lua",
      "init.lua"
    }

    for _, config_file in ipairs(config_files) do
      if filename == config_file then
        -- 静默处理配置文件更新
        vim.defer_fn(function()
          vim.notify(filename .. " 配置已更新", vim.log.levels.INFO, { 
            title = "配置更新",
            timeout = 1000, -- 1秒后自动消失
            hide_from_history = true -- 不保存到历史
          })
        end, 100)

        -- 防止显示 "Press ENTER or type command to continue" 提示
        vim.cmd("silent! echo ''")
        vim.cmd("redraw")
        break
      end
    end
  end,
  group = vim.api.nvim_create_augroup("GlobalSilentConfigReload", { clear = true })
})

if vim.g.config_change_detected then
  -- 尝试覆盖常见的配置更改检测
  local function silent_config_change_handler()
    -- 覆盖可能的配置更改检测函数
    -- 什么都不做，静默处理
    return true
  end
  vim.g.config_change_detected = silent_config_change_handler
end

-- 设置更激进的静默选项
-- vim.opt.cmdheight = 1  -- 减少命令高度
-- vim.opt.showcmd = false  -- 不显示命令
-- vim.opt.ruler = false  -- 不显示标尺

-- 禁用写入备份提示
vim.opt.writebackup = false
vim.opt.backup = false

