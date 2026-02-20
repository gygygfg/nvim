local M = {}

local function _set_keymap(mode, lhs, rhs, opts)
  opts = opts or { noremap = true, silent = true }
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.main()
  vim.g.mapleader = " "
  -- 配置 Ctrl+S 保存
  _set_keymap('n', '<C-s>', ':w<CR>')
  _set_keymap('i', '<C-s>', '<Esc>:w<CR>a')

  -- 取消高亮
  _set_keymap("n", "<leader>h", ":nohl<CR>")
end

function M.ufo()
  -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
  _set_keymap('n', 'zR', function() require('ufo').openAllFolds() end)
  _set_keymap('n', 'zM', function() require('ufo').closeAllFolds() end)
end

function M.mason()
  -- 检测当前缓冲区是否有 ast-grep LSP 客户端（使用新 API）
  local function has_ast_grep_client()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    for _, client in ipairs(clients) do
      if client.name == 'ast_grep' then
        return true
      end
    end
    return false
  end

  local use_ast_grep = has_ast_grep_client()

  -- lsp 快捷键设置
  -- 显示悬停文档
  _set_keymap('n', 'K', vim.lsp.buf.hover)

  -- 查找引用
  _set_keymap('n', 'gr', vim.lsp.buf.references)

  -- 重命名符号
  _set_keymap('n', '<leader>rn', vim.lsp.buf.rename)

  -- 代码操作
  _set_keymap("n", "<leader>ca", vim.lsp.buf.code_action)

  -- 查看工作区文件夹
  _set_keymap('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end)

  -- 查看定义 go to definition
  _set_keymap('n', 'gd', function()
    local params = vim.lsp.util.make_position_params(nil, 'utf-16')
    vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result)
      if not result then return end
      vim.lsp.util.jump_to_location(result[1], 'utf-16')
    end)
  end, { desc = "跳转定义" })

  -- 文档显示 show hover
  _set_keymap("n", "gh", vim.lsp.buf.hover)
  _set_keymap("n", "g[", vim.diagnostic.goto_prev)
  _set_keymap("n", "g]", vim.diagnostic.goto_next)
  _set_keymap('n', 'go', vim.diagnostic.open_float)
  _set_keymap('n', '<leader>q', vim.diagnostic.setloclist)

  -- 如果 ast-grep 可用，可以添加特定功能或通知
  if use_ast_grep then
    -- 可以在这里添加 ast-grep 特有的功能
    vim.defer_fn(function()
      vim.notify("ast-grep LSP 已加载", vim.log.levels.INFO)
    end, 100)
  end
end

function M.nvim_tree()
  -- nvim-tree
  _set_keymap("n", "<leader>d", ":NvimTreeToggle<CR>")
end

function M.comment()
  -- 快捷注释
  _set_keymap('n', '<leader>l', ':CommentToggle<CR>')
  _set_keymap('x', '<leader>l', ':CommentToggle<CR>')
end

function M.terminal()
  -- terminal
  _set_keymap('n', '<leader>t', ':ToggleTerm direction=float<CR>')
  _set_keymap('i', '<C-t>', '<Esc>:w!<CR>:ToggleTerm direction=float<CR>')
end

function M.code_runner()
  -- code_runner
  _set_keymap('n', '<leader>r', ':RunCode<CR>a', { noremap = true, silent = false })
  _set_keymap('n', '<leader>rc', ':RunClose<CR>', { noremap = true, silent = false })
end

function M.translate()
  -- 翻译
  -- Ti, 支持在底部输入框输入翻译。
  _set_keymap('n', 'ti', ':<C-u>Ti<CR>')

  -- Ty, 从粘贴板中获取文字进行翻译(匿名寄存器中"").
  _set_keymap('n', 'ty', ':<C-u>Ty<CR>')

  -- Tc, 支持翻译光标处单词。
  _set_keymap('n', 'tc', ':<C-u>Tc<CR>')

  -- Tv, 支持在visual模式下选中翻译。
  _set_keymap('v', 'tv', ':<C-u>Tv<CR>')

  -- Tr, 支持在visual模式下将文字替换成翻译。
  _set_keymap('v', 'tr', ':<C-u>Tr<CR>')
end

function M.codeCompanion()
  -- codeCompanion
  _set_keymap("n", "<leader>cc", ":CodeCompanionChat<CR>", { desc = "打开 CodeCompanionChat" })
  _set_keymap("v", "<leader>cp", ":CodeCompanionActions<CR>", { desc = "选区调用 CodeCompanion 动作" })
end

function M.treesitter_textobjects()
  -- nvim-treesitter textobjects 快捷键配置
  -- 这些快捷键已经在 nvim-treesitter.lua 中配置了 textobjects
  -- 这里只需要设置相关的快捷键

  -- 由于 textobjects 的快捷键已经在插件配置中定义（如 ]f, [f 等）
  -- 这里不需要额外设置，这个函数作为插件初始化使用

  -- 可以在这里添加一些与 treesitter textobjects 相关的额外快捷键
  -- 例如：
  -- _set_keymap('n', '<leader>ts', ':TSHighlightCapturesUnderCursor<CR>')

  -- 注意：这个函数被 nvim-treesitter.lua 的 init 选项调用
  -- 所以它应该执行实际的快捷键设置，而不是返回一个函数

  -- 添加 treesitter textobjects 相关的快捷键说明
  -- 以下快捷键由 nvim-treesitter textobjects 插件提供：
  -- [f: 跳转到上一个函数开头
  -- ]f: 跳转到下一个函数开头
  -- [m: 跳转到上一个类开头
  -- ]m: 跳转到下一个类开头

  -- 可以在这里添加额外的 textobjects 相关快捷键
  -- 例如，添加一个快捷键来显示当前光标下的 textobject 信息
  _set_keymap('n', '<leader>to', ':TSHighlightCapturesUnderCursor<CR>', { desc = "显示当前光标下的 treesitter 捕获信息" })
end

function M.fugitive()
  -- vim-fugitive 专用快捷键
  -- 在 Gstatus 窗口中的快捷键（安装后自动生效）
  -- s: 暂存/取消暂存文件
  -- u: 取消暂存
  -- cc: 提交
  -- ca: 修改提交
  -- ce: 修改提交（不编辑信息）
  _set_keymap("n", "<leader>gs", "<cmd>Gstatus<CR>", { desc = "[Git] 状态" })
  _set_keymap("n", "<leader>gd", "<cmd>Gdiff<CR>", { desc = "[Git] 差异" })
  _set_keymap("n", "<leader>gb", "<cmd>Gblame<CR>", { desc = "[Git] 追溯" })
  _set_keymap("n", "<leader>gp", "<cmd>Git push<CR>", { desc = "[Git] 推送" })
  _set_keymap("n", "<leader>gl", "<cmd>Git pull<CR>", { desc = "[Git] 拉取" })
  _set_keymap("n", "<leader>gw", "<cmd>Gwrite<CR>", { desc = "[Git] 暂存文件" })
  _set_keymap("n", "<leader>gr", "<cmd>Gread<CR>", { desc = "[Git] 检出文件" })

  vim.api.nvim_create_user_command("Gitignore", function()
    -- 生成.gitignore文件
    local filetypes = vim.fn.input("输入技术栈 (如 node,python): ")
    if filetypes ~= "" then
      local cmd = string.format("curl -sL https://www.toptal.com/developers/gitignore/api/%s > .gitignore", filetypes)
      vim.fn.system(cmd)
      vim.cmd("edit .gitignore")
      print("Gitignore 文件已生成")
    end
  end, {})

  vim.api.nvim_create_autocmd("BufReadPost", {
    -- 当检测到合并冲突时自动打开 diff 视图
    pattern = "*",
    callback = function()
      if vim.fn.search("^<<<<<<<", "nw") > 0 then
        vim.notify("检测到合并冲突，正在打开 Gdiff...", vim.log.levels.INFO)
        vim.defer_fn(function()
          vim.cmd("Gdiff")
        end, 100)
      end
    end
  })

  _set_keymap("n", "<leader>gbb", function()
    -- 快捷键：快速 blame 并定位问题
    vim.cmd("Gblame")
    -- 自动调整窗口布局
    vim.cmd("wincmd L")
    vim.cmd("vertical resize 40")
  end, { desc = "Git Blame (详细模式)" })

  -- 测试 git commit 功能的快捷键
  _set_keymap("n", "<leader>gt", function()
    -- 测试安全的 git commit 函数
    local test_messages = {
      "测试中文提交信息",
      "feat: 添加新功能",
      "fix: 修复bug",
      "chore: 更新依赖",
      "包含'单引号'的测试",
      "包含\"双引号\"的测试",
      "包含特殊字符!@#$%^&*()的测试",
      "移除测试文件和备份文件"  -- 这是原始错误信息
    }

    vim.ui.select(test_messages, {
      prompt = "选择测试提交信息:",
    }, function(choice)
      if choice then
        vim.notify("测试提交信息: " .. choice, vim.log.levels.INFO)
        -- 注释掉不存在的 safe_commit 模块调用
        -- local success, commit_hash_or_error, result = safe_commit.safe_git_commit(choice, { auto_stage = true })
        -- if success then
        --   if commit_hash_or_error ~= "" then
        --     vim.notify("✓ 测试成功: " .. commit_hash_or_error:sub(1, 8), vim.log.levels.INFO)
        --   else
        --     vim.notify("✓ 测试成功", vim.log.levels.INFO)
        --   end
        -- else
        --   vim.notify("✗ 测试失败: " .. commit_hash_or_error, vim.log.levels.ERROR)
        -- end
        vim.notify("✓ 测试功能已禁用（safe_commit 模块不存在）", vim.log.levels.WARN)
      end
    end)
  end, { desc = "测试 git commit 功能" })
  -- 配置快捷键
  _set_keymap("n", "<leader>gdc", function()
    vim.cmd("DiffviewOpen origin/main...HEAD")
  end, { desc = "查看并解决冲突" })

  _set_keymap("n", "<leader>gpp", function()
    -- 使用 rebase 方式合并当前分支并推送到远程
    local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")
    -- 使用异步执行避免阻塞界面
    vim.fn.jobstart({"git", "pull", "--rebase", "origin", branch}, {
      on_exit = function()
        vim.fn.jobstart({"git", "push", "origin", branch}, {
          on_exit = function()
            vim.notify("✓ 分支 " .. branch .. " 已成功推送", vim.log.levels.INFO)
          end
        })
      end
    })
  end, { desc = "使用 rebase 合并并推送当前分支" })
end

function M.telescope()
  -- 添加 telescope git_commits 快捷键
  _set_keymap("n", "<leader>gh", function()
    require("telescope.builtin").git_commits()
  end, { desc = "Git 提交历史 (telescope)" })
end

return M

